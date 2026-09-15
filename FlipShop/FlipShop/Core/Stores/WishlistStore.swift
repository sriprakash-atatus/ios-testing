/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

/// Products the shopper hearted, newest first. Persisted.
@MainActor
@Observable
final class WishlistStore {
    private(set) var items: [WishlistItem] = []

    @ObservationIgnored private let persistence: PersistenceStore

    init(persistence: PersistenceStore = .shared) {
        self.persistence = persistence
        items = persistence.load([WishlistItem].self, for: .wishlist) ?? []
    }

    var products: [Product] { items.map(\.product) }
    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }

    func contains(productID: String) -> Bool {
        items.contains { $0.id == productID }
    }

    /// Adds `product`, or removes it if it is already wishlisted. Returns whether it is wishlisted afterwards.
    @discardableResult
    func toggle(_ product: Product) -> Bool {
        if contains(productID: product.id) {
            remove(productID: product.id)
            return false
        }
        add(product)
        return true
    }

    func add(_ product: Product) {
        guard !contains(productID: product.id) else {
            return
        }
        items.insert(WishlistItem(product: product, addedAt: Date()), at: 0)
        persist()
    }

    /// Removes the product and returns its entry, so the caller can offer an undo.
    @discardableResult
    func remove(productID: String) -> WishlistItem? {
        guard let index = items.firstIndex(where: { $0.id == productID }) else {
            return nil
        }
        let removed = items.remove(at: index)
        persist()
        return removed
    }

    func restore(_ item: WishlistItem) {
        guard !contains(productID: item.id) else {
            return
        }
        items.insert(item, at: 0)
        persist()
    }

    /// Adds the product to `cart` with its first colour and size, and takes it off the wishlist if that worked.
    @discardableResult
    func moveToCart(productID: String, cart: CartStore) -> CartMutationResult {
        guard let item = items.first(where: { $0.id == productID }) else {
            return .outOfStock
        }
        let product = item.product
        let result = cart.add(product, color: product.colors.first?.name, size: product.sizes.first)
        if result.succeeded {
            remove(productID: productID)
        }
        return result
    }

    func clear() {
        items.removeAll()
        persist()
    }

    private func persist() {
        persistence.save(items, for: .wishlist)
    }
}
