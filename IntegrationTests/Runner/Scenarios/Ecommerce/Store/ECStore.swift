/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: The shop the `AtatusEcommerceScenario` runs — FlipShop, a marketplace laid out the way
// Indian shopping apps are: home feed, search, listings, wishlist, cart, address, payment and order
// tracking. Deliberately free of SDK imports: this scenario reports nothing by hand, so nothing in
// the store's own code talks to the agent. What reaches the intake is what auto-instrumentation
// captures from the screens appearing and the requests `ECStoreAPI` makes.

import Foundation
import UIKit

// MARK: - Catalog

/// A product, decoded straight from the store API's response.
///
/// Only `id`, `title`, `category`, `price` and `description` are required, so the app still reads a
/// backend that predates the marketplace fields: a product without an `mrp` simply shows no discount.
struct ECProduct: Equatable, Decodable {
    let id: Int
    let title: String
    let brand: String
    let category: String
    let price: Double
    /// The list price the discount is measured against.
    let mrp: Double
    let rating: Double
    let ratingCount: Int
    let description: String
    let highlights: [String]
    /// Whether the marketplace vouches for the seller — shown as the "Assured" tag.
    let isAssured: Bool

    init(
        id: Int,
        title: String,
        brand: String,
        category: String,
        price: Double,
        mrp: Double,
        rating: Double,
        ratingCount: Int,
        description: String,
        highlights: [String],
        isAssured: Bool
    ) {
        self.id = id
        self.title = title
        self.brand = brand
        self.category = category
        self.price = price
        self.mrp = mrp
        self.rating = rating
        self.ratingCount = ratingCount
        self.description = description
        self.highlights = highlights
        self.isAssured = isAssured
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, brand, category, price, mrp, rating, ratingCount, description, highlights, isAssured
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Read into a local first: `?? self.price` would capture `self` before it is initialized.
        let price = try container.decode(Double.self, forKey: .price)
        let mrp = try container.decodeIfPresent(Double.self, forKey: .mrp) ?? price
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        self.price = price
        self.mrp = max(mrp, price)
        description = try container.decode(String.self, forKey: .description)
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        ratingCount = try container.decodeIfPresent(Int.self, forKey: .ratingCount) ?? 0
        highlights = try container.decodeIfPresent([String].self, forKey: .highlights) ?? []
        isAssured = try container.decodeIfPresent(Bool.self, forKey: .isAssured) ?? false
    }

    var formattedPrice: String { ECMoney.format(price) }
    var formattedMRP: String { ECMoney.format(mrp) }

    /// Whole-percent discount off the MRP, `0` when the product sells at list price.
    var discountPercent: Int {
        guard mrp > price else {
            return 0
        }
        return Int(((mrp - price) / mrp * 100).rounded())
    }
}

/// A department on the home screen's category strip.
struct ECCategory: Equatable, Decodable {
    let id: String
    let name: String
    /// SF Symbol drawn on the category tile.
    let icon: String
}

/// A banner in the home screen's offer carousel. Tapping one opens its category.
struct ECOffer: Equatable, Decodable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
}

/// What the backend says about delivering a product to a pincode.
struct ECDeliveryEstimate: Decodable {
    let pincode: String
    let deliverable: Bool
    let days: Int
    let fee: Double
    let codAvailable: Bool

    var summary: String {
        guard deliverable else {
            return "Not deliverable to \(pincode)"
        }
        let charge = fee > 0 ? ECMoney.format(fee) : "Free"
        return "Delivery by \(ECDates.deliveryDate(inDays: days)) | \(charge)"
    }
}

/// One step of an order's journey, as the tracking timeline lists it.
struct ECTrackingStep: Decodable {
    let title: String
    let detail: String
    let isComplete: Bool
}

enum ECCatalog {
    static let categories: [ECCategory] = [
        ECCategory(id: "mobiles", name: "Mobiles", icon: "phone"),
        ECCategory(id: "electronics", name: "Electronics", icon: "headphones"),
        ECCategory(id: "fashion", name: "Fashion", icon: "bag"),
        ECCategory(id: "home", name: "Home", icon: "house"),
        ECCategory(id: "appliances", name: "Appliances", icon: "tv"),
        ECCategory(id: "toys", name: "Toys", icon: "gamecontroller"),
        ECCategory(id: "books", name: "Books", icon: "book"),
        ECCategory(id: "grocery", name: "Grocery", icon: "cart")
    ]

    static let offers: [ECOffer] = [
        ECOffer(id: "big-saving-days", title: "Big Saving Days", subtitle: "Up to 80% off on fashion", category: "fashion"),
        ECOffer(id: "electronics-sale", title: "Electronics Sale", subtitle: "Earbuds & headphones from ₹999", category: "electronics"),
        ECOffer(id: "mobile-bonanza", title: "Mobile Bonanza", subtitle: "Extra ₹2,000 off on exchange", category: "mobiles")
    ]

    /// Searches shown before the shopper types anything.
    static let trendingSearches = ["headphones", "5g mobile", "running shoes", "smart bulb", "mixer grinder"]

    /// Rendered when a catalog request fails — an offline runner still has screens to walk
    /// through, and the failed request is itself worth capturing. Mirrors the backend's catalog.
    static let fallback: [ECProduct] = [
        ECProduct(
            id: 1,
            title: "Nova 5G (Midnight Blue, 128 GB)",
            brand: "Nova",
            category: "mobiles",
            price: 17_999,
            mrp: 24_999,
            rating: 4.3,
            ratingCount: 182_345,
            description: "6.7\" AMOLED display, 50MP camera and a 5000 mAh battery.",
            highlights: ["8 GB RAM | 128 GB ROM", "6.7 inch Full HD+ AMOLED", "50MP + 8MP | 16MP front camera", "5000 mAh battery"],
            isAssured: true
        ),
        ECProduct(
            id: 2,
            title: "Aurora Wireless Headphones",
            brand: "Aurora",
            category: "electronics",
            price: 2_499,
            mrp: 5_999,
            rating: 4.2,
            ratingCount: 48_211,
            description: "Over-ear, 40h battery, active noise cancelling.",
            highlights: ["Active noise cancellation", "40 hours playback", "Bluetooth 5.3", "10 min charge = 5 h play"],
            isAssured: true
        ),
        ECProduct(
            id: 3,
            title: "Pulse Pro TWS Earbuds",
            brand: "Pulse",
            category: "electronics",
            price: 1_299,
            mrp: 3_999,
            rating: 4.1,
            ratingCount: 96_342,
            description: "Low-latency gaming mode, ENC mics, 50h with the case.",
            highlights: ["50 hours with case", "ENC calling mics", "40 ms gaming mode", "IPX5 water resistant"],
            isAssured: false
        ),
        ECProduct(
            id: 4,
            title: "Urban Trek Running Shoes",
            brand: "Urban Trek",
            category: "fashion",
            price: 1_199,
            mrp: 2_999,
            rating: 4.0,
            ratingCount: 35_610,
            description: "Breathable mesh upper, cushioned sole, lace-up.",
            highlights: ["Breathable mesh", "EVA cushioned sole", "Lightweight: 240 g"],
            isAssured: true
        ),
        ECProduct(
            id: 5,
            title: "Halo Smart LED Bulb 9W",
            brand: "Halo",
            category: "home",
            price: 399,
            mrp: 999,
            rating: 4.3,
            ratingCount: 120_455,
            description: "16M colours, voice assistant control, scheduling.",
            highlights: ["16 million colours", "Works with voice assistants", "Schedules and scenes"],
            isAssured: true
        ),
        ECProduct(
            id: 6,
            title: "ChefMate 750W Mixer Grinder",
            brand: "ChefMate",
            category: "appliances",
            price: 2_799,
            mrp: 4_499,
            rating: 4.2,
            ratingCount: 66_120,
            description: "Three stainless steel jars, overload protection.",
            highlights: ["750 W motor", "3 jars", "2 year warranty"],
            isAssured: false
        )
    ]

    /// The bundled products matching `query`, the way the backend's search matches them.
    static func search(_ query: String) -> [ECProduct] {
        let terms = query.lowercased().split(separator: " ").map(String.init)
        return fallback.filter { product in
            let haystack = "\(product.title) \(product.brand) \(product.category) \(product.description)".lowercased()
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    static func products(in category: String) -> [ECProduct] {
        fallback.filter { $0.category == category }
    }

    static func category(withID id: String) -> ECCategory {
        categories.first { $0.id == id } ?? ECCategory(id: id, name: id.capitalized, icon: "tag")
    }
}

/// How a listing orders its products. The raw value is what the store API takes as `sort`.
enum ECSortOrder: String, CaseIterable {
    case relevance
    case priceLowToHigh = "price_asc"
    case priceHighToLow = "price_desc"
    case discount

    var title: String {
        switch self {
        case .relevance: return "Relevance"
        case .priceLowToHigh: return "Price ↑"
        case .priceHighToLow: return "Price ↓"
        case .discount: return "Discount"
        }
    }

    /// Orders products locally, for when the listing is showing the bundled fallback.
    func sorted(_ products: [ECProduct]) -> [ECProduct] {
        switch self {
        case .relevance: return products
        case .priceLowToHigh: return products.sorted { $0.price < $1.price }
        case .priceHighToLow: return products.sorted { $0.price > $1.price }
        case .discount: return products.sorted { $0.discountPercent > $1.discountPercent }
        }
    }
}

enum ECMoney {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        // Indian digit grouping: ₹1,24,999.
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func format(_ amount: Double) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? String(format: "₹%.0f", amount)
    }
}

enum ECDates {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }()

    /// "Tue, 16 Sep" for the day an order placed now would arrive.
    static func deliveryDate(inDays days: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Checkout

/// Where the order ships.
struct ECAddress {
    var name: String
    var phone: String
    var pincode: String
    var line: String
    var city: String
    var type: String

    /// The address the form opens with, so the auto pilot has a valid one to deliver to.
    static let sample = ECAddress(
        name: "Priya Sharma",
        phone: "9876543210",
        pincode: "560034",
        line: "42, 3rd Cross, Koramangala 5th Block",
        city: "Bengaluru",
        type: "Home"
    )

    var summary: String { "\(line), \(city) – \(pincode)" }

    /// Why the address cannot be delivered to, or `nil` when it is complete.
    var validationError: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter the name of the receiver"
        }
        if phone.count != 10 || !phone.allSatisfy(\.isNumber) {
            return "Please enter a valid 10-digit mobile number"
        }
        if pincode.count != 6 || !pincode.allSatisfy(\.isNumber) {
            return "Please enter a valid 6-digit pincode"
        }
        if line.trimmingCharacters(in: .whitespaces).isEmpty || city.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter the full address"
        }
        return nil
    }
}

enum ECPaymentMethod: String, CaseIterable {
    case upi
    case card
    case netBanking = "net_banking"
    case cashOnDelivery = "cod"

    var title: String {
        switch self {
        case .upi: return "UPI"
        case .card: return "Credit / Debit / ATM Card"
        case .netBanking: return "Net Banking"
        case .cashOnDelivery: return "Cash on Delivery"
        }
    }

    var detail: String {
        switch self {
        case .upi: return "Pay by any UPI app"
        case .card: return "Card ending 4242"
        case .netBanking: return "All major banks supported"
        case .cashOnDelivery: return "Pay when your order arrives"
        }
    }

    var icon: String {
        switch self {
        case .upi: return "bolt.fill"
        case .card: return "creditcard"
        case .netBanking: return "building.columns"
        case .cashOnDelivery: return "indianrupeesign.circle"
        }
    }

    /// Cash on delivery places the order without taking a payment first.
    var requiresAuthorization: Bool { self != .cashOnDelivery }
}

/// What the confirmation screen shows. Captured when the order is placed, because placing it empties
/// the cart.
struct ECPlacedOrder {
    let reference: String
    let itemCount: Int
    let total: Double
    let address: ECAddress
    let paymentMethod: ECPaymentMethod
    let deliveryDays: Int
}

// MARK: - Cart

/// One line of the shopping cart.
struct ECCartLine {
    let product: ECProduct
    var quantity: Int

    var subtotal: Double { product.price * Double(quantity) }
    var mrpSubtotal: Double { product.mrp * Double(quantity) }
}

/// The shopper's cart, wishlist and checkout choices. Owned by `ECStoreNavigationController` and
/// handed to every screen it pushes, so the funnel shares one piece of state.
final class ECStore {
    private(set) var lines: [ECCartLine] = []
    private(set) var wishlist: [ECProduct] = []
    private(set) var lastOrder: ECPlacedOrder?

    var address: ECAddress = .sample
    var paymentMethod: ECPaymentMethod = .upi
    /// The pincode product pages check delivery against.
    var pincode = ECAddress.sample.pincode

    static let maximumQuantity = 5
    private static let deliveryFee = 40.0
    private static let freeDeliveryThreshold = 500.0

    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var isEmpty: Bool { lines.isEmpty }

    /// What the cart would cost at MRP.
    var mrpTotal: Double { lines.reduce(0) { $0 + $1.mrpSubtotal } }
    var subtotal: Double { lines.reduce(0) { $0 + $1.subtotal } }
    var discount: Double { mrpTotal - subtotal }
    var deliveryFee: Double { isEmpty || subtotal >= Self.freeDeliveryThreshold ? 0 : Self.deliveryFee }
    var total: Double { subtotal + deliveryFee }

    func contains(_ product: ECProduct) -> Bool {
        lines.contains { $0.product.id == product.id }
    }

    func add(_ product: ECProduct) {
        if let index = lines.firstIndex(where: { $0.product.id == product.id }) {
            lines[index].quantity = min(lines[index].quantity + 1, Self.maximumQuantity)
        } else {
            lines.append(ECCartLine(product: product, quantity: 1))
        }
    }

    /// Sets a line's quantity, clamped to what one order may hold. Returns the quantity applied.
    @discardableResult
    func setQuantity(_ quantity: Int, forProductID productID: Int) -> Int {
        guard let index = lines.firstIndex(where: { $0.product.id == productID }) else {
            return 0
        }
        let clamped = min(max(quantity, 1), Self.maximumQuantity)
        lines[index].quantity = clamped
        return clamped
    }

    func removeFromCart(productID: Int) {
        lines.removeAll { $0.product.id == productID }
    }

    func isWishlisted(_ product: ECProduct) -> Bool {
        wishlist.contains { $0.id == product.id }
    }

    /// Adds the product to the wishlist, or takes it off if it is already there. Returns whether it
    /// is wishlisted afterwards.
    @discardableResult
    func toggleWishlist(_ product: ECProduct) -> Bool {
        if isWishlisted(product) {
            removeFromWishlist(productID: product.id)
            return false
        }
        wishlist.append(product)
        return true
    }

    func removeFromWishlist(productID: Int) {
        wishlist.removeAll { $0.id == productID }
    }

    /// Records the order the payment screen created and empties the cart, as a placed order does.
    func completeOrder(reference: String, deliveryDays: Int) {
        lastOrder = ECPlacedOrder(
            reference: reference,
            itemCount: itemCount,
            total: total,
            address: address,
            paymentMethod: paymentMethod,
            deliveryDays: deliveryDays
        )
        lines.removeAll()
    }
}

// MARK: - Screens

/// A screen of the store. Gives each one the flow that pushed it; nothing else. RUM names these
/// screens through `EcommerceUIKitRUMViewsPredicate`, from the view controller class.
protocol ECStoreScreen: UIViewController {}

extension ECStoreScreen {
    /// The navigation controller driving the funnel, or `nil` if this screen is presented on its own.
    var flow: ECStoreNavigationController? { navigationController as? ECStoreNavigationController }

    /// The cart bar button every browsing screen carries, titled with the item count.
    func cartBarButton(store: ECStore, action: Selector) -> UIBarButtonItem {
        let button = UIBarButtonItem(title: cartTitle(store: store), style: .plain, target: self, action: action)
        button.accessibilityIdentifier = "Cart"
        return button
    }

    func cartTitle(store: ECStore) -> String {
        store.isEmpty ? "Cart" : "Cart (\(store.itemCount))"
    }
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

    /// Types `text` one character at a time, the way a shopper would, calling `update` with the text
    /// so far after each keystroke and `completion` once the whole of it is in.
    static func type(_ text: String, every interval: TimeInterval = 0.15, update: @escaping (String) -> Void, completion: @escaping () -> Void) {
        guard isEnabled else {
            return
        }
        for (index, _) in text.enumerated() {
            let prefix = String(text.prefix(index + 1))
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(index + 1)) {
                update(prefix)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(text.count + 2), execute: completion)
    }
}

// MARK: - Look

/// The store's shared look — a marketplace blue header, yellow and orange calls to action, green
/// ratings and discounts. Plain UIKit controls on purpose: Session Replay records the real view
/// tree, so the recording is only worth reading if the screens are.
enum ECStyle {
    static let brandBlue = UIColor(red: 40 / 255, green: 116 / 255, blue: 240 / 255, alpha: 1)
    static let brandYellow = UIColor(red: 255 / 255, green: 225 / 255, blue: 27 / 255, alpha: 1)
    static let buyNowOrange = UIColor(red: 251 / 255, green: 100 / 255, blue: 27 / 255, alpha: 1)
    static let offerGreen = UIColor(red: 56 / 255, green: 142 / 255, blue: 60 / 255, alpha: 1)
    static let accent = brandBlue
    static let pageBackground = UIColor.systemGroupedBackground
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
        button(title, background: buyNowOrange, foreground: .white, target: target, action: action)
    }

    static func secondaryButton(_ title: String, target: Any, action: Selector) -> UIButton {
        button(title, background: brandYellow, foreground: .black, target: target, action: action)
    }

    static func button(_ title: String, background: UIColor, foreground: UIColor, target: Any, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(foreground, for: .normal)
        button.setTitleColor(foreground.withAlphaComponent(0.5), for: .disabled)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = background
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = title
        button.addTarget(target, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    /// A small borderless text button, like "Remove" or "Check".
    static func linkButton(_ title: String, color: UIColor = brandBlue, target: Any, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.accessibilityIdentifier = title
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    /// A vertical stack pinned to the safe area, which the short store screens are laid out in.
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

    /// A vertical stack in a scroll view that fills the screen down to `bottomView` — the sticky action
    /// bar — or to the bottom safe area when there is none. The longer store screens are laid out in
    /// this.
    @discardableResult
    static func scrollingColumn(in view: UIView, arrangedSubviews: [UIView], above bottomView: UIView? = nil) -> (UIScrollView, UIStackView) {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomView?.topAnchor ?? view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -24)
        ])
        return (scrollView, stack)
    }

    /// A bar pinned to the bottom of the screen holding `arrangedSubviews` side by side at equal width —
    /// the sticky "Add to Cart | Buy Now" bar of a product page.
    static func bottomBar(in view: UIView, arrangedSubviews: [UIView]) -> UIView {
        let bar = UIView()
        bar.backgroundColor = .secondarySystemGroupedBackground
        bar.layer.shadowColor = UIColor.black.cgColor
        bar.layer.shadowOpacity = 0.12
        bar.layer.shadowOffset = CGSize(width: 0, height: -1)
        bar.layer.shadowRadius = 3
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)

        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(stack)

        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
        return bar
    }

    /// A white rounded panel around `arrangedSubviews`, which cards on the store's grey pages sit in.
    static func card(_ arrangedSubviews: [UIView], spacing: CGFloat = 8) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 8

        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .vertical
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])
        return card
    }

    /// A stand-in product photo: the category's symbol on a tinted square. The store bundles no
    /// images, and a symbol still gives the replay something recognisable to draw.
    static func productImage(for product: ECProduct, side: CGFloat) -> UIView {
        let symbol = ECCatalog.category(withID: product.category).icon
        let tint = tints[abs(product.id) % tints.count]

        let container = UIView()
        container.backgroundColor = tint.withAlphaComponent(0.12)
        container.layer.cornerRadius = 6
        container.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(systemName: symbol))
        imageView.tintColor = tint
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: side),
            container.heightAnchor.constraint(equalToConstant: side),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.5)
        ])
        return container
    }

    private static let tints: [UIColor] = [.systemBlue, .systemPink, .systemOrange, .systemTeal, .systemPurple, .systemGreen]

    /// The green "4.3 ★" badge.
    static func ratingBadge(_ rating: Double) -> UIView {
        let label = UILabel()
        label.text = String(format: "%.1f ★", rating)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .white
        label.textAlignment = .center

        let badge = UIView()
        badge.backgroundColor = offerGreen
        badge.layer.cornerRadius = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -2),
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -6)
        ])
        badge.setContentHuggingPriority(.required, for: .horizontal)
        return badge
    }

    /// The rating badge followed by the number of ratings, e.g. "4.3 ★  1,82,345 ratings".
    static func ratingRow(for product: ECProduct) -> UIStackView {
        let count = NumberFormatter.localizedString(from: NSNumber(value: product.ratingCount), number: .decimal)
        var views: [UIView] = [ratingBadge(product.rating), label("\(count) ratings", style: .caption1, color: .secondaryLabel)]
        if product.isAssured {
            views.append(label("✓ Assured", style: .caption1, color: brandBlue))
        }
        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    /// Price, the MRP struck through, and the discount — "₹2,499  ₹5,999  58% off".
    static func priceRow(for product: ECProduct, style: UIFont.TextStyle) -> UIStackView {
        let price = label(product.formattedPrice, style: style)
        price.font = .preferredFont(forTextStyle: style).bold()
        var views: [UIView] = [price]

        if product.discountPercent > 0 {
            let mrp = label("", style: .subheadline, color: .secondaryLabel)
            mrp.attributedText = NSAttributedString(
                string: product.formattedMRP,
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            views.append(mrp)
            views.append(label("\(product.discountPercent)% off", style: .subheadline, color: offerGreen))
        }
        views.forEach { $0.setContentCompressionResistancePriority(.required, for: .horizontal) }
        views.append(UIView())

        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .firstBaseline
        return row
    }

    /// A line of a price breakdown: a title on the left, an amount on the right.
    static func amountRow(_ title: String, _ amount: String, color: UIColor = .label, emphasised: Bool = false) -> UIStackView {
        let style: UIFont.TextStyle = emphasised ? .headline : .body
        let amountLabel = label(amount, style: style, color: color)
        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label(title, style: style), amountLabel])
        row.axis = .horizontal
        row.spacing = spacing
        return row
    }

    static func separator() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    static func sectionHeader(_ title: String) -> UILabel {
        let header = label(title, style: .headline)
        header.font = .preferredFont(forTextStyle: .headline).bold()
        return header
    }

    /// The "Cart — Address — Payment" progress strip at the top of each checkout step.
    static func checkoutSteps(current: Int) -> UIView {
        let steps = ["Cart", "Address", "Payment"]
        let views: [UIView] = steps.enumerated().map { index, name -> UIView in
            let isDone = index < current
            let isCurrent = index == current
            let marker = isDone ? "✓" : "\(index + 1)"
            let color: UIColor = isDone || isCurrent ? brandBlue : .secondaryLabel
            let step = label("\(marker)  \(name)", style: .subheadline, color: color)
            step.textAlignment = .center
            if isCurrent {
                step.font = .preferredFont(forTextStyle: .subheadline).bold()
            }
            return step
        }
        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.distribution = .fillEqually
        return card([row])
    }

    /// Replaces every arranged subview of `stack`, for screens that redraw after the cart changes.
    static func replaceArrangedSubviews(of stack: UIStackView, with views: [UIView]) {
        stack.arrangedSubviews.forEach { view in
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        views.forEach(stack.addArrangedSubview)
    }
}

/// A tappable container for the store's tiles — search box, categories, banners, deals. Its content
/// never takes the touch itself, so each tap reaches the control, and RUM names the action after the
/// tile's accessibility identifier rather than after whichever label happened to be under the finger.
final class ECTapTile: UIControl {
    init(content: UIView, identifier: String, insets: UIEdgeInsets = .zero) {
        super.init(frame: .zero)
        accessibilityIdentifier = identifier
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }
}

extension UIFont {
    /// This font with the bold trait added, or unchanged if the face has no bold variant.
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(.traitBold)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
