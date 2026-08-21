/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Cart screen of the store in `AtatusEcommerceScenario`.

import UIKit

/// What is in the cart, what it costs, and the way to checkout.
final class ECCartViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private var hasStartedCheckout = false

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

        title = "Cart"
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "Cart"

        let lines = UIStackView(arrangedSubviews: store.lines.map {
            row("\($0.quantity)× \($0.product.title)", ECMoney.format($0.subtotal), emphasised: false)
        })
        lines.axis = .vertical
        lines.spacing = 8

        ECStyle.column(in: view, arrangedSubviews: [
            ECStyle.label("\(store.itemCount) item(s)", style: .subheadline, color: .secondaryLabel),
            lines,
            separator(),
            row("Subtotal", ECMoney.format(store.subtotal), emphasised: false),
            row("Shipping", ECMoney.format(store.shipping), emphasised: false),
            row("Total", ECMoney.format(store.total), emphasised: true),
            ECStyle.primaryButton("Checkout", target: self, action: #selector(didTapCheckout))
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ECAutoPilot.step(after: 2.5) { [weak self] in self?.didTapCheckout() }
    }

    // MARK: - Actions

    @objc
    private func didTapCheckout() {
        guard !hasStartedCheckout else {
            return
        }
        hasStartedCheckout = true
        flow?.showCheckout()
    }

    // MARK: - Layout

    private func separator() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    private func row(_ title: String, _ amount: String, emphasised: Bool) -> UIStackView {
        let style: UIFont.TextStyle = emphasised ? .headline : .body
        let amountLabel = ECStyle.label(amount, style: style, color: emphasised ? ECStyle.accent : .label)
        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [ECStyle.label(title, style: style), amountLabel])
        row.axis = .horizontal
        row.spacing = ECStyle.spacing
        return row
    }
}
