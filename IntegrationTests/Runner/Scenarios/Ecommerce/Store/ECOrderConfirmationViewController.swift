/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Last screen of the store in `AtatusEcommerceScenario`.

import UIKit

/// Confirms the order, shows where it is going, tracks it, and ends the funnel.
final class ECOrderConfirmationViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private let timeline = UIStackView()
    private var visit = 0

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

        title = "Order Confirmed"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = true
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Order Confirmation"

        timeline.axis = .vertical
        timeline.spacing = 0

        var sections: [UIView] = []
        if let order = store.lastOrder {
            sections = [summaryCard(for: order), deliveryCard(for: order), ECStyle.card([ECStyle.sectionHeader("Track order"), timeline], spacing: 12)]
        }
        timeline.addArrangedSubview(ECStyle.label("Loading tracking details…", style: .footnote, color: .secondaryLabel))

        let bar = ECStyle.bottomBar(in: view, arrangedSubviews: [
            ECStyle.primaryButton("Continue Shopping", target: self, action: #selector(didTapContinue))
        ])
        ECStyle.scrollingColumn(in: view, arrangedSubviews: sections, above: bar)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        guard visit == 1, let order = store.lastOrder else {
            return
        }
        api.loadTracking(reference: order.reference, deliveryDays: order.deliveryDays) { [weak self] steps in
            self?.showTimeline(steps)
        }
    }

    // MARK: - Layout

    private func summaryCard(for order: ECPlacedOrder) -> UIView {
        let check = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        check.tintColor = ECStyle.offerGreen
        check.contentMode = .scaleAspectFit
        check.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let payment = order.paymentMethod.requiresAuthorization
            ? "\(ECMoney.format(order.total)) paid via \(order.paymentMethod.title)"
            : "Pay \(ECMoney.format(order.total)) on delivery"

        let labels = [
            ECStyle.label("Order placed successfully!", style: .title2),
            ECStyle.label("Order ID: \(order.reference)", style: .headline, color: ECStyle.brandBlue),
            ECStyle.label("\(order.itemCount) item(s) · \(payment)", style: .subheadline, color: .secondaryLabel)
        ]
        labels.forEach { $0.textAlignment = .center }

        return ECStyle.card([check] + (labels as [UIView]), spacing: 8)
    }

    private func deliveryCard(for order: ECPlacedOrder) -> UIView {
        ECStyle.card([
            ECStyle.sectionHeader("Delivering to"),
            ECStyle.label("\(order.address.name) · \(order.address.phone)", style: .subheadline),
            ECStyle.label(order.address.summary, style: .subheadline, color: .secondaryLabel),
            ECStyle.label("Delivery by \(ECDates.deliveryDate(inDays: order.deliveryDays))", style: .headline, color: ECStyle.offerGreen)
        ])
    }

    /// The order's journey as a vertical rail: a filled check for each step done, a hollow circle for
    /// each still to come, joined by a line coloured to match.
    private func showTimeline(_ steps: [ECTrackingStep]) {
        let rows = steps.enumerated().map { index, step -> UIView in
            let dot = UIImageView(image: UIImage(systemName: step.isComplete ? "checkmark.circle.fill" : "circle"))
            dot.tintColor = step.isComplete ? ECStyle.offerGreen : .tertiaryLabel
            dot.setContentHuggingPriority(.required, for: .vertical)
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 22),
                dot.heightAnchor.constraint(equalToConstant: 22)
            ])

            // The last step has nothing below it to join, but keeps a clear connector so every rail
            // stretches the same way.
            let isLast = index == steps.count - 1
            let connector = UIView()
            connector.backgroundColor = isLast ? UIColor.clear : (step.isComplete ? ECStyle.offerGreen : UIColor.separator)
            NSLayoutConstraint.activate([
                connector.widthAnchor.constraint(equalToConstant: 2),
                connector.heightAnchor.constraint(greaterThanOrEqualToConstant: 16)
            ])

            let rail = UIStackView(arrangedSubviews: [dot, connector])
            rail.axis = .vertical
            rail.spacing = 2
            rail.alignment = .center

            let title = ECStyle.label(step.title, style: .body, color: step.isComplete ? .label : .secondaryLabel)
            let text = UIStackView(arrangedSubviews: [
                title,
                ECStyle.label(step.detail, style: .caption1, color: .secondaryLabel),
                UIView()
            ])
            text.axis = .vertical
            text.spacing = 2

            let row = UIStackView(arrangedSubviews: [rail, text])
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .fill
            return row
        }
        ECStyle.replaceArrangedSubviews(of: timeline, with: rows)
    }

    // MARK: - Actions

    @objc
    private func didTapContinue() {
        flow?.returnToHome()
    }
}
