/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

/// The cart, items saved for later and the applied coupon. Persisted, so the cart survives relaunches.
@MainActor
@Observable
final class CartStore {
    private(set) var items: [CartItem] = []
    private(set) var savedForLater: [CartItem] = []
    private(set) var appliedCoupon: Coupon?
    private(set) var availableCoupons: [Coupon] = []
    /// Set when a change to the cart made the applied coupon stop qualifying, and it was removed.
    private(set) var couponNotice: String?
    /// The delivery speed the cart's estimate is priced with. Checkout starts from it.
    var deliveryOption: DeliveryOption = .standard

    @ObservationIgnored private let service: any CartServiceProtocol
    @ObservationIgnored private let persistence: PersistenceStore

    init(service: any CartServiceProtocol, persistence: PersistenceStore = .shared) {
        self.service = service
        self.persistence = persistence
        items = persistence.load([CartItem].self, for: .cart) ?? []
        savedForLater = persistence.load([CartItem].self, for: .savedForLater) ?? []
        appliedCoupon = persistence.load(Coupon.self, for: .appliedCoupon)
    }

    // MARK: - Reading

    var isEmpty: Bool { items.isEmpty }
    /// Units across every line — what the tab badge shows.
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var breakdown: PriceBreakdown { PriceBreakdown(lines: items, coupon: appliedCoupon, delivery: deliveryOption) }
    var hasUnavailableItems: Bool { items.contains { !$0.product.isInStock } }

    func contains(productID: String) -> Bool {
        items.contains { $0.product.id == productID }
    }

    /// Units of `productID` across all its variants.
    func quantity(ofProductID productID: String) -> Int {
        items.filter { $0.product.id == productID }.reduce(0) { $0 + $1.quantity }
    }

    func item(withID id: String) -> CartItem? {
        items.first { $0.id == id }
    }

    // MARK: - Changing

    @discardableResult
    func add(_ product: Product, quantity: Int = 1, color: String? = nil, size: String? = nil) -> CartMutationResult {
        guard product.isInStock else {
            return .outOfStock
        }
        let maximum = product.purchasableQuantity
        let id = CartItem.makeID(productID: product.id, color: color, size: size)

        let result: CartMutationResult
        if let index = items.firstIndex(where: { $0.id == id }) {
            let wanted = items[index].quantity + quantity
            items[index].quantity = min(wanted, maximum)
            result = wanted > maximum ? .limitReached(maximum: maximum) : .updated(quantity: wanted)
        } else {
            items.insert(CartItem(product: product, quantity: min(quantity, maximum), selectedColor: color, selectedSize: size), at: 0)
            result = quantity > maximum ? .limitReached(maximum: maximum) : .added
        }
        savedForLater.removeAll { $0.id == id }
        didChange()
        return result
    }

    @discardableResult
    func setQuantity(_ quantity: Int, forItemID id: String) -> CartMutationResult {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return .outOfStock
        }
        let maximum = max(items[index].product.purchasableQuantity, 1)
        let applied = min(max(quantity, 1), maximum)
        items[index].quantity = applied
        didChange()
        return quantity > maximum ? .limitReached(maximum: maximum) : .updated(quantity: applied)
    }

    @discardableResult
    func increment(itemID: String) -> CartMutationResult {
        guard let item = item(withID: itemID) else {
            return .outOfStock
        }
        return setQuantity(item.quantity + 1, forItemID: itemID)
    }

    /// Takes one unit off, stopping at one — removing a line is a separate, explicit action.
    func decrement(itemID: String) {
        guard let item = item(withID: itemID), item.quantity > 1 else {
            return
        }
        setQuantity(item.quantity - 1, forItemID: itemID)
    }

    /// Removes a line and returns it, so the caller can offer an undo.
    @discardableResult
    func remove(itemID: String) -> CartItem? {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else {
            return nil
        }
        let removed = items.remove(at: index)
        didChange()
        return removed
    }

    /// Puts back a line removed with `remove(itemID:)`.
    func restore(_ item: CartItem) {
        guard !items.contains(where: { $0.id == item.id }) else {
            return
        }
        items.insert(item, at: 0)
        didChange()
    }

    func saveForLater(itemID: String) {
        guard let removed = remove(itemID: itemID) else {
            return
        }
        savedForLater.removeAll { $0.id == removed.id }
        savedForLater.insert(removed, at: 0)
        didChange()
    }

    @discardableResult
    func moveToCart(savedItemID: String) -> CartMutationResult {
        guard let saved = savedForLater.first(where: { $0.id == savedItemID }) else {
            return .outOfStock
        }
        let result = add(saved.product, quantity: saved.quantity, color: saved.selectedColor, size: saved.selectedSize)
        if result.succeeded {
            savedForLater.removeAll { $0.id == savedItemID }
            didChange()
        }
        return result
    }

    func removeSaved(itemID: String) {
        savedForLater.removeAll { $0.id == itemID }
        didChange()
    }

    /// Empties the cart after an order is placed. Saved-for-later items stay.
    func clear() {
        items.removeAll()
        appliedCoupon = nil
        couponNotice = nil
        didChange()
    }

    // MARK: - Coupons

    func loadCoupons() async {
        guard availableCoupons.isEmpty else {
            return
        }
        availableCoupons = (try? await service.availableCoupons()) ?? []
    }

    /// Validates and applies `code`. Throws a validation error explaining why a code was refused.
    @discardableResult
    func applyCoupon(code: String) async throws -> Coupon {
        let coupon = try await service.validateCoupon(code: code, subtotal: breakdown.subtotal)
        appliedCoupon = coupon
        couponNotice = nil
        didChange()
        return coupon
    }

    func removeCoupon() {
        appliedCoupon = nil
        couponNotice = nil
        didChange()
    }

    func clearCouponNotice() {
        couponNotice = nil
    }

    // MARK: - Private

    private func didChange() {
        if let coupon = appliedCoupon, !coupon.isEligible(forSubtotal: breakdown.subtotal) {
            appliedCoupon = nil
            couponNotice = items.isEmpty ? nil : "\(coupon.code) was removed — your cart no longer meets the minimum order of \(Formatters.currency(coupon.minimumOrderValue))."
        }
        persistence.save(items, for: .cart)
        persistence.save(savedForLater, for: .savedForLater)
        if let coupon = appliedCoupon {
            persistence.save(coupon, for: .appliedCoupon)
        } else {
            persistence.remove(.appliedCoupon)
        }
    }
}
