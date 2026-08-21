/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Last screen of the store in `AtatusEcommerceScenario`.

import UIKit

/// Confirms the order and ends the funnel.
final class ECOrderConfirmationViewController: UIViewController, ECStoreScreen {
    private let store: ECStore

    init(store: ECStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Order Confirmed"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "Order Confirmation"

        ECStyle.column(in: view, arrangedSubviews: [
            ECStyle.label("Thank you", style: .largeTitle),
            ECStyle.label("Order \(store.orderReference ?? "—")", style: .headline, color: ECStyle.accent),
            ECStyle.label("\(store.itemCount) item(s) · \(ECMoney.format(store.total))", style: .body),
            ECStyle.label("Arriving in 2–4 business days.", style: .subheadline, color: .secondaryLabel),
            ECStyle.primaryButton("Continue Shopping", target: self, action: #selector(didTapContinue))
        ])
    }

    @objc
    private func didTapContinue() {
        flow?.returnToCatalog()
    }
}
