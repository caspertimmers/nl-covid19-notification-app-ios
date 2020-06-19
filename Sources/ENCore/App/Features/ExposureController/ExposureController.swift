/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import UIKit

final class ExposureController: ExposureControlling {

    init(mutableStateStream: MutableExposureStateStreaming,
         exposureManager: ExposureManaging?,
         dataController: ExposureDataControlling) {
        self.mutableStateStream = mutableStateStream
        self.exposureManager = exposureManager
        self.dataController = dataController
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - ExposureControlling

    func activate() {
        guard let exposureManager = exposureManager else {
            updateStatusStream()
            return
        }

        exposureManager.activate { _ in
            self.updateStatusStream()
        }
    }

    func requestExposureNotificationPermission() {
        exposureManager?.setExposureNotificationEnabled(true) { _ in
            self.updateStatusStream()
        }
    }

    func requestPushNotificationPermission(_ completion: @escaping (() -> ())) {
        let uncc = UNUserNotificationCenter.current()

        uncc.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }

        uncc.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func confirmExposureNotification() {
        // Not implemented yet
    }

    func requestLabConfirmationKey(completion: @escaping (Result<ConfirmationKey, ExposureDataError>) -> ()) {
        let convertConfirmationKey: (LabConfirmationKey) -> ConfirmationKey = { labConfirmationKey in
            return (confirmationKey: labConfirmationKey.identifier,
                    expiration: labConfirmationKey.validUntil)
        }

        let receiveCompletion: (Subscribers.Completion<ExposureDataError>) -> () = { result in
            if case let .failure(error) = result {
                completion(.failure(error))
            }
        }

        let receiveValue: (ConfirmationKey) -> () = { key in
            completion(.success(key))
        }

        dataController
            .requestLabConfirmationKey()
            .map(convertConfirmationKey)
            .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
            .store(in: &disposeBag)
    }

    func requestUploadKeys(completion: @escaping (Bool) -> ()) {}

    // MARK: - Private

    private func updateStatusStream() {
        guard let exposureManager = exposureManager else {
            mutableStateStream.update(state: .init(notifiedState: notifiedState,
                                                   activeState: .inactive(.requiresOSUpdate)))
            return
        }

        let activeState: ExposureActiveState

        switch exposureManager.getExposureNotificationStatus() {
        case .active:
            activeState = .active
        case let .inactive(error) where error == .bluetoothOff:
            activeState = .inactive(.bluetoothOff)
        case let .inactive(error) where error == .disabled || error == .restricted:
            activeState = .inactive(.disabled)
        case let .inactive(error) where error == .notAuthorized:
            activeState = .notAuthorized
        case let .inactive(error) where error == .unknown:
            // Most likely due to code signing issues
            activeState = .inactive(.disabled)
        case .inactive:
            activeState = .inactive(.disabled)
        case .notAuthorized:
            activeState = .notAuthorized
        case .authorizationDenied:
            activeState = .authorizationDenied
        }

        mutableStateStream.update(state: .init(notifiedState: notifiedState, activeState: activeState))
    }

    private var notifiedState: ExposureNotificationState {
        // TODO: Replace with right value
        return .notNotified
    }

    private let mutableStateStream: MutableExposureStateStreaming
    private let exposureManager: ExposureManaging?
    private let dataController: ExposureDataControlling
    private var disposeBag = Set<AnyCancellable>()
}