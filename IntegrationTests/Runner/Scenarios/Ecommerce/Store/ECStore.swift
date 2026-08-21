/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: The shop the `AtatusEcommerceScenario` runs — catalog, cart and screens. Deliberately free
// of SDK imports: this scenario reports nothing by hand, so nothing in the store's own code talks to
// the agent. What reaches the intake is what auto-instrumentation captures from the screens
// appearing and the requests `ECStoreAPI` makes.

import Foundation
import UIKit

// MARK: - Catalog

/// A product, decoded straight from the store API's response.
struct ECProduct: Equatable, Decodable {
    let id: Int
    let title: String
    let category: String
    let price: Double
    let description: String

    var formattedPrice: String { ECMoney.format(price) }
}

enum ECCatalog {
    /// Rendered when the catalog request fails — an offline runner still has screens to walk
    /// through, and the failed request is itself worth capturing.
    static let fallback: [ECProduct] = [
        ECProduct(
            id: 1,
            title: "Aurora Wireless Headphones",
            category: "audio",
            price: 249,
            description: "Over-ear, 40h battery, active noise cancelling."
        ),
        ECProduct(
            id: 2,
            title: "Meridian Mechanical Keyboard",
            category: "accessories",
            price: 159,
            description: "75% layout, hot-swap switches, USB-C."
        ),
        ECProduct(
            id: 3,
            title: "Halo Smart Lamp",
            category: "home",
            price: 74.5,
            description: "16M colours, scheduling, matte aluminium base."
        ),
        ECProduct(
            id: 4,
            title: "Trailhead Daypack 22L",
            category: "outdoor",
            price: 112,
            description: "Recycled ripstop, laptop sleeve, rain cover."
        ),
        ECProduct(
            id: 5,
            title: "Kettle Pour-Over Set",
            category: "kitchen",
            price: 59.9,
            description: "Gooseneck kettle, glass carafe, reusable filter."
        )
    ]
}

enum ECMoney {
    static func format(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}

// MARK: - Cart

/// One line of the shopping cart.
struct ECCartLine {
    let product: ECProduct
    var quantity: Int

    var subtotal: Double { product.price * Double(quantity) }
}

/// The shopper's cart. Owned by `ECStoreNavigationController` and handed to every screen it pushes,
/// so the funnel shares one piece of state.
final class ECStore {
    private(set) var lines: [ECCartLine] = []
    private(set) var orderReference: String?

    private static let shippingFee = 4.99

    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var subtotal: Double { lines.reduce(0) { $0 + $1.subtotal } }
    var shipping: Double { lines.isEmpty ? 0 : Self.shippingFee }
    var total: Double { subtotal + shipping }
    var isEmpty: Bool { lines.isEmpty }

    func add(_ product: ECProduct) {
        if let index = lines.firstIndex(where: { $0.product == product }) {
            lines[index].quantity += 1
        } else {
            lines.append(ECCartLine(product: product, quantity: 1))
        }
    }

    /// Records the order the checkout screen created, for the confirmation screen to show.
    func placeOrder(reference: String) {
        orderReference = reference
    }
}

// MARK: - Screens

/// A screen of the store. Gives each one the flow that pushed it; nothing else. RUM names these
/// screens itself, from the view controller class.
protocol ECStoreScreen: UIViewController {}

extension ECStoreScreen {
    /// The navigation controller driving the funnel, or `nil` if this screen is presented on its own.
    var flow: ECStoreNavigationController? { navigationController as? ECStoreNavigationController }
}

// MARK: - Auto pilot

/// Walks the funnel without a test runner: CI launches the app with `simctl launch` and nothing taps
/// for it, so each screen schedules its own next step. Every step is also wired to a real control,
/// so the same screens behave normally — and report auto-instrumented tap actions — when a person
/// drives them.
enum ECAutoPilot {
    /// Set to `false` to leave the store on whichever screen it is showing.
    static var isEnabled = true

    static func step(after delay: TimeInterval, _ action: @escaping () -> Void) {
        guard isEnabled else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }
}

// MARK: - Look

/// The store's shared look. Plain UIKit controls on purpose: Session Replay records the real view
/// tree, so the recording is only worth reading if the screens are.
enum ECStyle {
    static let accent = UIColor.systemIndigo
    static let spacing: CGFloat = 16

    static func label(_ text: String, style: UIFont.TextStyle, color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static func primaryButton(_ title: String, target: Any, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = accent
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = title
        button.addTarget(target, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    /// A vertical stack pinned to the safe area, which every store screen is laid out in.
    @discardableResult
    static func column(in view: UIView, arrangedSubviews: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: spacing),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing)
        ])
        return stack
    }
}
