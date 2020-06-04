/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol OnboardingConsentViewControllable: ViewControllable { }

final class OnboardingConsentViewController: ViewController, OnboardingConsentViewControllable {

    lazy private var viewsInDisplayOrder: [UIView] = []

    init(listener: OnboardingConsentListener) {
        self.listener = listener

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Implement or delete
    }

    // MARK: - Private

    private weak var listener: OnboardingConsentListener?
    private lazy var internalView: OnboardingConsentView = OnboardingConsentView()
}

private final class OnboardingConsentView: View {
    override func build() {
        super.build()

        // TODO: Construct View here or delete this function
    }

    override func setupConstraints() {
        super.setupConstraints()

        // TODO: Setup constraints here or delete this function
    }
}
