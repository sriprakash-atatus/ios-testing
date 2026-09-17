/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

// MARK: - Cart

protocol CartServiceProtocol: Sendable {
    func availableCoupons() async throws -> [Coupon]
    /// The coupon for `code` if it exists and `subtotal` qualifies; otherwise a validation error saying why.
    func validateCoupon(code: String, subtotal: Double) async throws -> Coupon
}

struct MockCartService: CartServiceProtocol {
    static let coupons: [Coupon] = [
        Coupon(code: "WELCOME10", title: "10% off your order", details: "Up to ₹500 off on orders above ₹999", kind: .percentage, value: 10, maximumDiscount: 500, minimumOrderValue: 999),
        Coupon(code: "FLAT200", title: "Flat ₹200 off", details: "On orders above ₹1,499", kind: .flat, value: 200, maximumDiscount: nil, minimumOrderValue: 1_499),
        Coupon(code: "SAVE25", title: "25% off big orders", details: "Up to ₹2,500 off on orders above ₹9,999", kind: .percentage, value: 25, maximumDiscount: 2_500, minimumOrderValue: 9_999),
        Coupon(code: "FREESHIP", title: "Free delivery", details: "Free delivery on any order", kind: .freeDelivery, value: 0, maximumDiscount: nil, minimumOrderValue: 0)
    ]

    func availableCoupons() async throws -> [Coupon] {
        try await MockNetwork.delay(0.2...0.4)
        return Self.coupons
    }

    func validateCoupon(code: String, subtotal: Double) async throws -> Coupon {
        try await MockNetwork.delay(0.5...0.9)
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()
        guard let coupon = Self.coupons.first(where: { $0.code == normalized }) else {
            throw APIError.validation(message: "“\(normalized)” isn't a valid coupon code.")
        }
        guard coupon.isEligible(forSubtotal: subtotal) else {
            let shortfall = Formatters.currency(coupon.shortfall(forSubtotal: subtotal))
            throw APIError.validation(message: "Add items worth \(shortfall) more to use \(coupon.code).")
        }
        return coupon
    }
}

// MARK: - Payments

protocol PaymentServiceProtocol: Sendable {
    /// Authorises `amount`. Returns `nil` for cash on delivery, which is collected later.
    func authorize(amount: Double, with selection: PaymentSelection) async throws -> PaymentReceipt?
}

/// Simulated payments — nothing leaves the device. Cards ending `0002` and UPI handles containing
/// `fail` are declined, so the failure path can be demonstrated.
struct MockPaymentService: PaymentServiceProtocol {
    func authorize(amount: Double, with selection: PaymentSelection) async throws -> PaymentReceipt? {
        switch selection {
        case .cashOnDelivery:
            try await MockNetwork.delay(0.4...0.7)
            return nil
        case .card(let card):
            try await MockNetwork.delay(1.2...2.0)
            if card.last4 == "0002" {
                throw APIError.paymentDeclined(message: "Your bank declined this card. Try a different payment method.")
            }
            if card.isExpired() {
                throw APIError.paymentDeclined(message: "This card has expired. Choose another card.")
            }
        case .upi(let handle):
            try await MockNetwork.delay(1.5...2.4)
            if handle.lowercased().contains("fail") {
                throw APIError.paymentDeclined(message: "The UPI request timed out. Approve it in your UPI app and try again.")
            }
        case .applePay:
            try await MockNetwork.delay(1.0...1.6)
        }
        return PaymentReceipt(
            transactionID: "TXN" + String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)).uppercased(),
            amount: amount,
            method: selection.kind,
            authorizedAt: Date()
        )
    }
}

// MARK: - Orders

struct OrderRequest: Sendable {
    let items: [CartItem]
    let address: Address
    let deliveryOption: DeliveryOption
    let payment: PaymentSelection
    let coupon: Coupon?
    let pricing: PriceBreakdown
}

protocol OrderServiceProtocol: Sendable {
    /// The account's order history. Seeded from `catalog` the first time, so a new install has orders to show.
    func fetchOrders(for user: User?, catalog: [Product]) async throws -> [Order]
    func placeOrder(_ request: OrderRequest) async throws -> Order
    func cancelOrder(_ order: Order) async throws -> Order
    /// The order's latest tracking status.
    func trackOrder(_ order: Order) async throws -> Order
}

struct MockOrderService: OrderServiceProtocol {
    /// How long after placing an app order each stage is reached, so a demo session can watch one move.
    private static let stageDelays: [OrderStatus: TimeInterval] = [
        .confirmed: 20,
        .packed: 90,
        .shipped: 4 * 60,
        .outForDelivery: 10 * 60,
        .delivered: 20 * 60
    ]

    func fetchOrders(for user: User?, catalog: [Product]) async throws -> [Order] {
        try await MockNetwork.delay()
        guard user != nil, catalog.count >= 6 else {
            return []
        }
        return seededOrders(from: catalog)
    }

    func placeOrder(_ request: OrderRequest) async throws -> Order {
        try await MockNetwork.delay(0.8...1.4)
        guard !request.items.isEmpty else {
            throw APIError.validation(message: "Your cart is empty.")
        }
        if let unavailable = request.items.first(where: { !$0.product.isInStock }) {
            throw APIError.validation(message: "\(unavailable.product.name) just went out of stock. Remove it to continue.")
        }
        let now = Date()
        return Order(
            id: Self.orderNumber(for: now),
            items: request.items.map(OrderItem.init(cartItem:)),
            shippingAddress: request.address,
            deliveryOption: request.deliveryOption,
            payment: request.payment,
            pricing: request.pricing,
            couponCode: request.coupon?.code,
            placedAt: now,
            estimatedDelivery: request.deliveryOption.estimatedDelivery(from: now),
            status: .placed,
            events: [OrderStatusEvent(status: .placed, date: now, note: OrderStatus.placed.detail)],
            advancesAutomatically: true
        )
    }

    func cancelOrder(_ order: Order) async throws -> Order {
        try await MockNetwork.delay(0.6...1.0)
        guard order.isCancellable else {
            throw APIError.validation(message: "This order has already shipped and can no longer be cancelled.")
        }
        var cancelled = order
        cancelled.status = .cancelled
        cancelled.events.append(OrderStatusEvent(status: .cancelled, date: Date(), note: "Cancelled at your request. Any payment will be refunded in 3–5 days."))
        return cancelled
    }

    func trackOrder(_ order: Order) async throws -> Order {
        try await MockNetwork.delay(0.3...0.6)
        guard order.advancesAutomatically, order.status != .cancelled else {
            return order
        }
        var updated = order
        let elapsed = Date().timeIntervalSince(order.placedAt)
        for stage in OrderStatus.trackingStages.dropFirst() where updated.event(for: stage) == nil {
            guard let delay = Self.stageDelays[stage], elapsed >= delay else {
                break
            }
            updated.events.append(OrderStatusEvent(status: stage, date: order.placedAt.addingTimeInterval(delay), note: stage.detail))
            updated.status = stage
        }
        return updated
    }

    static func orderNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        return "FS\(formatter.string(from: date))\(Int.random(in: 100_000...999_999))"
    }

    /// Three past orders and one on its way, built from real catalog products.
    private func seededOrders(from catalog: [Product]) -> [Order] {
        let inStock = catalog.filter(\.isInStock)
        func pick(_ index: Int) -> Product { inStock[index % inStock.count] }
        let address = MockUserService.demoAddresses[0]
        let now = Date()
        let day: TimeInterval = 24 * 60 * 60

        func order(number: String, daysAgo: Double, lines: [(Product, Int)], option: DeliveryOption, payment: PaymentSelection, reached: OrderStatus) -> Order {
            let placedAt = now.addingTimeInterval(-daysAgo * day)
            let items = lines.map { CartItem(product: $0.0, quantity: $0.1, selectedColor: $0.0.colors.first?.name, selectedSize: $0.0.sizes.first) }
            var events: [OrderStatusEvent] = []
            var status = OrderStatus.placed
            if reached == .cancelled {
                events = [
                    OrderStatusEvent(status: .placed, date: placedAt, note: OrderStatus.placed.detail),
                    OrderStatusEvent(status: .cancelled, date: placedAt.addingTimeInterval(3_600), note: "Cancelled at your request. Refund completed.")
                ]
                status = .cancelled
            } else {
                let lastIndex = reached.stageIndex ?? 0
                for (index, stage) in OrderStatus.trackingStages.enumerated() where index <= lastIndex {
                    let offset = Double(index) / Double(OrderStatus.trackingStages.count - 1) * Double(max(option.maximumDays, 1)) * day
                    events.append(OrderStatusEvent(status: stage, date: placedAt.addingTimeInterval(offset), note: stage.detail))
                }
                status = reached
            }
            return Order(
                id: number,
                items: items.map(OrderItem.init(cartItem:)),
                shippingAddress: address,
                deliveryOption: option,
                payment: payment,
                pricing: PriceBreakdown(lines: items, coupon: nil, delivery: option),
                couponCode: nil,
                placedAt: placedAt,
                estimatedDelivery: option.estimatedDelivery(from: placedAt),
                status: status,
                events: events,
                advancesAutomatically: false
            )
        }

        return [
            order(number: "FS\(Self.datePart(now.addingTimeInterval(-2 * day)))418305", daysAgo: 2, lines: [(pick(3), 1)], option: .standard,
                  payment: .upi(handle: MockUserService.demoUPI.handle), reached: .shipped),
            order(number: "FS\(Self.datePart(now.addingTimeInterval(-9 * day)))290114", daysAgo: 9, lines: [(pick(11), 1), (pick(27), 2)], option: .express,
                  payment: .card(MockUserService.demoCards[0]), reached: .delivered),
            order(number: "FS\(Self.datePart(now.addingTimeInterval(-24 * day)))775201", daysAgo: 24, lines: [(pick(40), 1)], option: .standard,
                  payment: .cashOnDelivery, reached: .delivered),
            order(number: "FS\(Self.datePart(now.addingTimeInterval(-41 * day)))120987", daysAgo: 41, lines: [(pick(58), 1)], option: .standard,
                  payment: .applePay, reached: .cancelled)
        ]
    }

    private static func datePart(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        return formatter.string(from: date)
    }
}

// MARK: - User

struct PaymentMethodsPayload: Codable, Sendable {
    let cards: [SavedCard]
    let upiIDs: [SavedUPI]
}

protocol UserServiceProtocol: Sendable {
    func updateProfile(_ user: User) async throws -> User
    func fetchAddresses(for user: User?) async throws -> [Address]
    func saveAddress(_ address: Address) async throws -> Address
    func deleteAddress(id: String) async throws
    func fetchPaymentMethods(for user: User?) async throws -> PaymentMethodsPayload
    /// Registers a card from its details. Only the brand, last four digits and expiry come back; the
    /// number itself is never kept.
    func addCard(number: String, holderName: String, expiryMonth: Int, expiryYear: Int, nickname: String) async throws -> SavedCard
    func deleteCard(id: String) async throws
    func addUPI(handle: String) async throws -> SavedUPI
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws
}

struct MockUserService: UserServiceProtocol {
    static let demoAddresses: [Address] = [
        Address(id: "addr_home", fullName: "Priya Sharma", phone: "9876543210", line1: "Flat 402, Prestige Lakeside Habitat",
                line2: "Varthur Main Road, Whitefield", landmark: "Opposite Forum Mall", city: "Bengaluru", state: "Karnataka",
                pincode: "560066", type: .home, isDefault: true),
        Address(id: "addr_work", fullName: "Priya Sharma", phone: "9876543210", line1: "4th Floor, Embassy Tech Square",
                line2: "Outer Ring Road, Kadubeesanahalli", landmark: "", city: "Bengaluru", state: "Karnataka",
                pincode: "560103", type: .work, isDefault: false)
    ]

    static let demoCards: [SavedCard] = [
        SavedCard(id: "card_hdfc", brand: .visa, last4: "4242", holderName: "PRIYA SHARMA", expiryMonth: 8, expiryYear: 2029, nickname: "HDFC Regalia"),
        SavedCard(id: "card_declined", brand: .mastercard, last4: "0002", holderName: "PRIYA SHARMA", expiryMonth: 11, expiryYear: 2028, nickname: "Declines (demo)")
    ]

    static let demoUPI = SavedUPI(id: "upi_hdfc", handle: "priya@okhdfcbank")

    func updateProfile(_ user: User) async throws -> User {
        try await MockNetwork.delay(0.5...0.9)
        guard Validator.isValidName(user.name) else {
            throw APIError.validation(message: "Enter your full name.")
        }
        guard Validator.isValidEmail(user.email) else {
            throw APIError.validation(message: "Enter a valid email address.")
        }
        guard Validator.isValidPhone(user.phone) else {
            throw APIError.validation(message: "Enter a valid 10-digit mobile number.")
        }
        return user
    }

    func fetchAddresses(for user: User?) async throws -> [Address] {
        try await MockNetwork.delay(0.2...0.5)
        guard let user = user else {
            return []
        }
        return Self.demoAddresses.map { address in
            var address = address
            address.fullName = user.name
            address.phone = user.phone
            return address
        }
    }

    func saveAddress(_ address: Address) async throws -> Address {
        try await MockNetwork.delay(0.4...0.8)
        guard Validator.isValidPincode(address.pincode) else {
            throw APIError.validation(message: "Enter a valid 6-digit pincode.")
        }
        if address.pincode.hasPrefix("9") {
            throw APIError.validation(message: "Sorry, we don't deliver to \(address.pincode) yet.")
        }
        return address
    }

    func deleteAddress(id: String) async throws {
        try await MockNetwork.delay(0.3...0.6)
    }

    func fetchPaymentMethods(for user: User?) async throws -> PaymentMethodsPayload {
        try await MockNetwork.delay(0.2...0.5)
        guard user != nil else {
            return PaymentMethodsPayload(cards: [], upiIDs: [])
        }
        return PaymentMethodsPayload(cards: Self.demoCards, upiIDs: [Self.demoUPI])
    }

    func addCard(number: String, holderName: String, expiryMonth: Int, expiryYear: Int, nickname: String) async throws -> SavedCard {
        try await MockNetwork.delay(0.8...1.4)
        guard Validator.isValidCardNumber(number) else {
            throw APIError.validation(message: "Check the card number and try again.")
        }
        guard Validator.isValidExpiry(month: expiryMonth, year: expiryYear) else {
            throw APIError.validation(message: "This card has expired.")
        }
        let digits = Validator.digits(in: number)
        let brand = CardBrand.detect(fromNumber: digits)
        return SavedCard(
            id: "card_\(UUID().uuidString.prefix(8).lowercased())",
            brand: brand,
            last4: String(digits.suffix(4)),
            holderName: holderName.uppercased(),
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            nickname: nickname.isEmpty ? brand.title : nickname
        )
    }

    func deleteCard(id: String) async throws {
        try await MockNetwork.delay(0.3...0.6)
    }

    func addUPI(handle: String) async throws -> SavedUPI {
        try await MockNetwork.delay(0.6...1.0)
        guard Validator.isValidUPI(handle) else {
            throw APIError.validation(message: "Enter a valid UPI ID, like name@bank.")
        }
        return SavedUPI(id: "upi_\(UUID().uuidString.prefix(8).lowercased())", handle: handle.lowercased())
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        try await MockNetwork.delay(0.2...0.4)
    }
}

// MARK: - Container

/// Every service the app talks to. Swap `.mock` for real implementations to connect a backend.
struct AppServices: Sendable {
    let products: any ProductServiceProtocol
    let search: any SearchServiceProtocol
    let auth: any AuthServiceProtocol
    let cart: any CartServiceProtocol
    let orders: any OrderServiceProtocol
    let payments: any PaymentServiceProtocol
    let users: any UserServiceProtocol

    static let mock = AppServices(
        products: MockProductService(),
        search: MockSearchService(),
        auth: MockAuthService(),
        cart: MockCartService(),
        orders: MockOrderService(),
        payments: MockPaymentService(),
        users: MockUserService()
    )
}
