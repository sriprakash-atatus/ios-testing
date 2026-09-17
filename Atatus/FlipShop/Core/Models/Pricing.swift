/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

enum DeliveryOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case standard
    case express
    case sameDay

    /// Standard delivery is free from this order value.
    static let freeDeliveryThreshold: Double = 499

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard Delivery"
        case .express: return "Express Delivery"
        case .sameDay: return "Same-Day Delivery"
        }
    }

    var subtitle: String {
        switch self {
        case .standard: return "Delivered in 3–5 business days"
        case .express: return "Delivered in 1–2 business days"
        case .sameDay: return "Order before 2 PM, delivered by 9 PM"
        }
    }

    var symbolName: String {
        switch self {
        case .standard: return "shippingbox"
        case .express: return "bolt.fill"
        case .sameDay: return "clock.badge.checkmark"
        }
    }

    /// The latest the order arrives, in days after it is placed.
    var maximumDays: Int {
        switch self {
        case .standard: return 5
        case .express: return 2
        case .sameDay: return 0
        }
    }

    func fee(forSubtotal subtotal: Double) -> Double {
        switch self {
        case .standard: return subtotal >= Self.freeDeliveryThreshold ? 0 : 40
        case .express: return 99
        case .sameDay: return 149
        }
    }

    func estimatedDelivery(from date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: maximumDays, to: date) ?? date
    }
}

/// Everything an order costs, line by line.
struct PriceBreakdown: Hashable, Codable, Sendable {
    /// GST applied to the amount after coupon discounts.
    static let taxRate = 0.05

    var itemCount: Int
    /// What the items would cost at MRP.
    var originalTotal: Double
    /// What the items cost at their selling prices.
    var subtotal: Double
    /// `originalTotal - subtotal`.
    var productDiscount: Double
    var couponDiscount: Double
    var deliveryFee: Double
    var tax: Double
    var total: Double

    static let zero = PriceBreakdown(
        itemCount: 0,
        originalTotal: 0,
        subtotal: 0,
        productDiscount: 0,
        couponDiscount: 0,
        deliveryFee: 0,
        tax: 0,
        total: 0
    )

    init(
        itemCount: Int,
        originalTotal: Double,
        subtotal: Double,
        productDiscount: Double,
        couponDiscount: Double,
        deliveryFee: Double,
        tax: Double,
        total: Double
    ) {
        self.itemCount = itemCount
        self.originalTotal = originalTotal
        self.subtotal = subtotal
        self.productDiscount = productDiscount
        self.couponDiscount = couponDiscount
        self.deliveryFee = deliveryFee
        self.tax = tax
        self.total = total
    }

    /// Prices `lines` with `coupon` (if it qualifies) and `delivery`.
    init(lines: [CartItem], coupon: Coupon?, delivery: DeliveryOption) {
        let itemCount = lines.reduce(0) { $0 + $1.quantity }
        let originalTotal = lines.reduce(0) { $0 + $1.lineOriginalTotal }
        let subtotal = lines.reduce(0) { $0 + $1.lineTotal }
        let couponDiscount = coupon?.discount(onSubtotal: subtotal) ?? 0
        let waivesDelivery = coupon.map { $0.waivesDelivery && $0.isEligible(forSubtotal: subtotal) } ?? false
        let deliveryFee = lines.isEmpty || waivesDelivery ? 0 : delivery.fee(forSubtotal: subtotal)
        let taxable = max(subtotal - couponDiscount, 0)
        let tax = (taxable * Self.taxRate).rounded()

        self.init(
            itemCount: itemCount,
            originalTotal: originalTotal,
            subtotal: subtotal,
            productDiscount: max(originalTotal - subtotal, 0),
            couponDiscount: couponDiscount,
            deliveryFee: deliveryFee,
            tax: tax,
            total: taxable + deliveryFee + tax
        )
    }

    /// Everything the shopper saves against MRP.
    var totalSavings: Double { productDiscount + couponDiscount }
}
