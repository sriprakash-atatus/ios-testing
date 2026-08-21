/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Checkout screen of the store in `AtatusEcommerceScenario`. The one step of the funnel that
// fails on purpose — the first authorisation is sent to a path the store API does not serve, so the
// run captures a genuinely failed request alongside the successful ones. Nothing about the failure
// is reported by hand; the agent sees the response like it sees every other.

import UIKit

/// Takes payment for the cart, retries once after the first authorisation fails, then creates the
/// order.
final class ECCheckoutViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private let statusLabel = ECStyle.label("Ready to pay", style: .footnote, color: .secondaryLabel)
    private lazy var payButton = ECStyle.primaryButton(
        "Pay \(ECMoney.format(store.total))",
        target: self,
        action: #selector(didTapPay)
    )
    private var attempt = 0

    init(store: ECStore, api: ECStoreAPI) {
        self.store = store
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Checkout"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "Checkout"

        ECStyle.column(in: view, arrangedSubviews: [
            ECStyle.label("Order summary", style: .headline),
            ECStyle.label("\(store.itemCount) item(s)", style: .subheadline, color: .secondaryLabel),
            ECStyle.label(ECMoney.format(store.total), style: .title1, color: ECStyle.accent),
            ECStyle.label("Card ending 4242", style: .footnote, color: .secondaryLabel),
            payButton,
            statusLabel
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ECAutoPilot.step(after: 2.5) { [weak self] in self?.didTapPay() }
    }

    // MARK: - Payment

    @objc
    private func didTapPay() {
        guard payButton.isEnabled else {
            return
        }
        attempt += 1

        // The first authorisation goes to a path that is not served and fails; the retry goes to one
        // that is and succeeds. Scripted rather than random, so every run captures the same failure
        // and the same recovery.
        let shouldSucceed = attempt > 1

        payButton.isEnabled = false
        statusLabel.text = attempt == 1 ? "Authorising payment…" : "Retrying payment…"

        api.authorizePayment(amount: store.total, succeeds: shouldSucceed) { [weak self] succeeded in
            guard let self = self else {
                return
            }
            if succeeded {
                self.createOrder()
            } else {
                self.authorizationFailed()
            }
        }
    }

    private func authorizationFailed() {
        statusLabel.text = "Payment could not be authorised — retrying"
        payButton.setTitle("Retry Payment", for: .normal)
        payButton.isEnabled = true

        // A shopper would try again, so the funnel does too.
        ECAutoPilot.step(after: 2.5) { [weak self] in self?.didTapPay() }
    }

    private func createOrder() {
        statusLabel.text = "Payment authorised — creating order…"

        api.placeOrder(lines: store.lines) { [weak self] reference in
            guard let self = self else {
                return
            }
            self.store.placeOrder(reference: reference ?? "ORD-PENDING")
            self.flow?.showOrderConfirmation()
        }
    }
}
