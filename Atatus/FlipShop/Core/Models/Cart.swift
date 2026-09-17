/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

/// One line of the cart: a product in a chosen colour and size.
struct CartItem: Identifiable, Hashable, Codable, Sendable {
    /// Unique per product *and* variant, so the same shoe in two sizes is two lines.
    let id: String
    let product: Product
    var quantity: Int
    let selectedColor: String?
    let selectedSize: String?
    let addedAt: Date

    init(product: Product, quantity: Int, selectedColor: String? = nil, selectedSize: String? = nil, addedAt: Date = Date()) {
        self.id = CartItem.makeID(productID: product.id, color: selectedColor, size: selectedSize)
        self.product = product
        self.quantity = quantity
        self.selectedColor = selectedColor
        self.selectedSize = selectedSize
        self.addedAt = addedAt
    }

    static func makeID(productID: String, color: String?, size: String?) -> String {
        [productID, color ?? "-", size ?? "-"].joined(separator: "|")
    }

    var lineTotal: Double { product.price * Double(quantity) }
    var lineOriginalTotal: Double { product.originalPrice * Double(quantity) }

    /// "Graphite · 256 GB", or `nil` when the product has no variants.
    var variantDescription: String? {
        let parts = [selectedColor, selectedSize].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// A product the shopper hearted.
struct WishlistItem: Identifiable, Hashable, Codable, Sendable {
    let product: Product
    let addedAt: Date

    var id: String { product.id }
}

/// What adding to or changing the cart did.
enum CartMutationResult: Equatable, Sendable {
    case added
    case updated(quantity: Int)
    /// The quantity was capped at this many — the stock or the per-order limit.
    case limitReached(maximum: Int)
    case outOfStock

    var succeeded: Bool {
        switch self {
        case .added, .updated: return true
        case .limitReached, .outOfStock: return false
        }
    }
}

struct Coupon: Identifiable, Hashable, Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case percentage
        case flat
        case freeDelivery
    }

    let code: String
    let title: String
    let details: String
    let kind: Kind
    /// The percentage for `.percentage`, the rupee amount for `.flat`, unused for `.freeDelivery`.
    let value: Double
    let maximumDiscount: Double?
    let minimumOrderValue: Double

    var id: String { code }

    func isEligible(forSubtotal subtotal: Double) -> Bool {
        subtotal >= minimumOrderValue
    }

    /// How much short of the minimum order `subtotal` is, or `0` when it qualifies.
    func shortfall(forSubtotal subtotal: Double) -> Double {
        max(minimumOrderValue - subtotal, 0)
    }

    /// The rupees this coupon takes off `subtotal`. Free-delivery coupons take nothing off the items.
    func discount(onSubtotal subtotal: Double) -> Double {
        guard isEligible(forSubtotal: subtotal) else {
            return 0
        }
        switch kind {
        case .percentage:
            let amount = (subtotal * value / 100).rounded()
            return min(amount, maximumDiscount ?? amount)
        case .flat:
            return min(value, subtotal)
        case .freeDelivery:
            return 0
        }
    }

    var waivesDelivery: Bool { kind == .freeDelivery }
}
