/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

/// What is being checked out.
enum CheckoutSource: Hashable, Sendable {
    /// Everything in the cart.
    case cart
    /// One product bought straight from its page, without touching the cart.
    case buyNow(CartItem)
}

enum CheckoutStep: Int, CaseIterable, Identifiable, Comparable, Sendable {
    case address
    case delivery
    case payment
    case review

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .address: return "Address"
        case .delivery: return "Delivery"
        case .payment: return "Payment"
        case .review: return "Summary"
        }
    }

    var symbolName: String {
        switch self {
        case .address: return "mappin.and.ellipse"
        case .delivery: return "shippingbox"
        case .payment: return "creditcard"
        case .review: return "checklist"
        }
    }

    static func < (lhs: CheckoutStep, rhs: CheckoutStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// One checkout, from choosing an address to placing the order. Created when checkout opens.
@MainActor
@Observable
final class CheckoutStore {
    let source: CheckoutSource
    private(set) var step: CheckoutStep = .address
    /// The furthest step reached, so the step indicator can jump back to any step already visited.
    private(set) var furthestStep: CheckoutStep = .address
    var selectedAddressID: String?
    var deliveryOption: DeliveryOption
    var payment: PaymentSelection?
    private(set) var isPlacingOrder = false
    var errorMessage: String?
    private(set) var placedOrder: Order?

    @ObservationIgnored private let cart: CartStore
    @ObservationIgnored private let account: AccountStore
    @ObservationIgnored private let orders: OrderStore
    @ObservationIgnored private let payments: any PaymentServiceProtocol

    init(source: CheckoutSource, cart: CartStore, account: AccountStore, orders: OrderStore, payments: any PaymentServiceProtocol) {
        self.source = source
        self.cart = cart
        self.account = account
        self.orders = orders
        self.payments = payments
        self.deliveryOption = cart.deliveryOption
        self.selectedAddressID = account.defaultAddress?.id
    }

    // MARK: - Reading

    var items: [CartItem] {
        switch source {
        case .cart: return cart.items
        case .buyNow(let item): return [item]
        }
    }

    /// Coupons apply to cart checkouts only.
    var coupon: Coupon? {
        source == .cart ? cart.appliedCoupon : nil
    }

    var breakdown: PriceBreakdown {
        PriceBreakdown(lines: items, coupon: coupon, delivery: deliveryOption)
    }

    var selectedAddress: Address? {
        account.addresses.first { $0.id == selectedAddressID }
    }

    var estimatedDelivery: Date {
        deliveryOption.estimatedDelivery(from: Date())
    }

    var isCashOnDeliveryAvailable: Bool {
        breakdown.total <= PaymentSelection.cashOnDeliveryLimit
    }

    /// Same-day delivery needs an order before 2 PM to a metro pincode (those starting 11, 40, 56 or 60).
    func isAvailable(_ option: DeliveryOption, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard option == .sameDay else {
            return true
        }
        let hour = calendar.component(.hour, from: now)
        let pincode = selectedAddress?.pincode ?? ""
        return hour < 14 && ["11", "40", "56", "60"].contains { pincode.hasPrefix($0) }
    }

    var canContinue: Bool {
        switch step {
        case .address:
            return selectedAddress != nil
        case .delivery:
            return isAvailable(deliveryOption)
        case .payment:
            guard let payment = payment else {
                return false
            }
            return payment.kind != .cashOnDelivery || isCashOnDeliveryAvailable
        case .review:
            return !items.isEmpty && !isPlacingOrder && !items.contains { !$0.product.isInStock }
        }
    }

    /// From 0 to 1, for the progress bar.
    var progress: Double {
        Double(step.rawValue + 1) / Double(CheckoutStep.allCases.count)
    }

    // MARK: - Moving between steps

    func continueToNextStep() {
        guard canContinue, let next = CheckoutStep(rawValue: step.rawValue + 1) else {
            return
        }
        step = next
        furthestStep = max(furthestStep, next)
    }

    /// Goes back one step. Returns `false` on the first step, where going back means leaving checkout.
    @discardableResult
    func goBack() -> Bool {
        guard let previous = CheckoutStep(rawValue: step.rawValue - 1) else {
            return false
        }
        step = previous
        return true
    }

    /// Jumps to a step already reached.
    func go(to target: CheckoutStep) {
        guard target <= furthestStep else {
            return
        }
        step = target
    }

    // MARK: - Placing the order

    /// Authorises the payment and places the order. On failure `errorMessage` says why and `nil` comes back.
    func placeOrder() async -> Order? {
        guard !isPlacingOrder else {
            return nil
        }
        guard let address = selectedAddress else {
            errorMessage = "Choose a delivery address."
            step = .address
            return nil
        }
        guard let payment = payment else {
            errorMessage = "Choose how you'd like to pay."
            step = .payment
            return nil
        }
        guard !items.isEmpty else {
            errorMessage = "Your cart is empty."
            return nil
        }

        isPlacingOrder = true
        errorMessage = nil
        defer { isPlacingOrder = false }

        let pricing = breakdown
        do {
            _ = try await payments.authorize(amount: pricing.total, with: payment)
            let request = OrderRequest(items: items, address: address, deliveryOption: deliveryOption, payment: payment, coupon: coupon, pricing: pricing)
            let order = try await orders.place(request)
            if source == .cart {
                cart.clear()
            }
            placedOrder = order
            return order
        } catch {
            errorMessage = APIError.message(for: error)
            return nil
        }
    }
}
