/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

enum OrderStatus: String, CaseIterable, Codable, Sendable, Comparable {
    case placed
    case confirmed
    case packed
    case shipped
    case outForDelivery
    case delivered
    case cancelled

    /// The stages tracking walks through, in order. Cancelled is not one of them.
    static let trackingStages: [OrderStatus] = [.placed, .confirmed, .packed, .shipped, .outForDelivery, .delivered]

    var title: String {
        switch self {
        case .placed: return "Order Placed"
        case .confirmed: return "Confirmed"
        case .packed: return "Packed"
        case .shipped: return "Shipped"
        case .outForDelivery: return "Out for Delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }

    var detail: String {
        switch self {
        case .placed: return "We have received your order."
        case .confirmed: return "The seller has confirmed your order."
        case .packed: return "Your items are packed and ready to ship."
        case .shipped: return "Your package is on its way."
        case .outForDelivery: return "Our delivery partner is on the way to you."
        case .delivered: return "Your package was delivered."
        case .cancelled: return "This order was cancelled."
        }
    }

    var symbolName: String {
        switch self {
        case .placed: return "cart.badge.plus"
        case .confirmed: return "checkmark.seal"
        case .packed: return "shippingbox"
        case .shipped: return "truck.box"
        case .outForDelivery: return "box.truck.badge.clock"
        case .delivered: return "house.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    /// Position in `trackingStages`, or `nil` for a cancelled order.
    var stageIndex: Int? { Self.trackingStages.firstIndex(of: self) }

    /// The stage after this one, or `nil` once delivered or cancelled.
    var next: OrderStatus? {
        guard let index = stageIndex, index + 1 < Self.trackingStages.count else {
            return nil
        }
        return Self.trackingStages[index + 1]
    }

    static func < (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
        (lhs.stageIndex ?? -1) < (rhs.stageIndex ?? -1)
    }
}

struct OrderStatusEvent: Identifiable, Hashable, Codable, Sendable {
    let status: OrderStatus
    let date: Date
    let note: String

    var id: String { status.rawValue }
}

struct OrderItem: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let product: Product
    let quantity: Int
    let selectedColor: String?
    let selectedSize: String?
    /// The price paid per unit, fixed when the order was placed.
    let unitPrice: Double

    init(id: String, product: Product, quantity: Int, selectedColor: String?, selectedSize: String?, unitPrice: Double) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.selectedColor = selectedColor
        self.selectedSize = selectedSize
        self.unitPrice = unitPrice
    }

    init(cartItem: CartItem) {
        self.init(
            id: cartItem.id,
            product: cartItem.product,
            quantity: cartItem.quantity,
            selectedColor: cartItem.selectedColor,
            selectedSize: cartItem.selectedSize,
            unitPrice: cartItem.product.price
        )
    }

    var lineTotal: Double { unitPrice * Double(quantity) }

    var variantDescription: String? {
        let parts = [selectedColor, selectedSize].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct Order: Identifiable, Hashable, Codable, Sendable {
    /// The order number shown to the shopper, e.g. `FS260911482913`.
    let id: String
    let items: [OrderItem]
    let shippingAddress: Address
    let deliveryOption: DeliveryOption
    let payment: PaymentSelection
    let pricing: PriceBreakdown
    let couponCode: String?
    let placedAt: Date
    let estimatedDelivery: Date
    var status: OrderStatus
    /// One event per stage reached, oldest first.
    var events: [OrderStatusEvent]
    /// Whether tracking advances on its own as time passes — true for orders placed in the app, so a
    /// demo session can watch an order move; false for the seeded order history.
    let advancesAutomatically: Bool

    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var isActive: Bool { status != .delivered && status != .cancelled }
    var isCancellable: Bool { status != .cancelled && status < .shipped }
    var deliveredAt: Date? { event(for: .delivered)?.date }
    var headlineProduct: Product? { items.first?.product }

    func event(for status: OrderStatus) -> OrderStatusEvent? {
        events.first { $0.status == status }
    }

    /// "iPhone 13 Pro and 2 more items".
    var summaryTitle: String {
        guard let first = items.first else {
            return "Order \(id)"
        }
        let others = items.count - 1
        return others > 0 ? "\(first.product.name) and \(others) more item\(others == 1 ? "" : "s")" : first.product.name
    }
}
