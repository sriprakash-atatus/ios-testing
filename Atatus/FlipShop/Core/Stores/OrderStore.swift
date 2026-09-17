/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

/// The account's orders, newest first. Persisted.
@MainActor
@Observable
final class OrderStore {
    private(set) var orders: [Order] = []
    private(set) var state: LoadState = .idle

    @ObservationIgnored private let service: any OrderServiceProtocol
    @ObservationIgnored private let persistence: PersistenceStore

    init(service: any OrderServiceProtocol, persistence: PersistenceStore = .shared) {
        self.service = service
        self.persistence = persistence
        if let cached = persistence.load([Order].self, for: .orders) {
            orders = cached
            state = .loaded
        }
    }

    var activeOrders: [Order] { orders.filter(\.isActive) }
    var pastOrders: [Order] { orders.filter { !$0.isActive } }

    func order(id: String) -> Order? {
        orders.first { $0.id == id }
    }

    // MARK: - Loading

    /// Loads the order history once. A signed-in account with nothing cached gets its history from the service.
    func loadIfNeeded(for user: User?, catalog: [Product]) async {
        guard state != .loaded, !state.isLoading else {
            return
        }
        await refresh(for: user, catalog: catalog)
    }

    func refresh(for user: User?, catalog: [Product]) async {
        state = .loading
        do {
            let fetched = try await service.fetchOrders(for: user, catalog: catalog)
            // Orders placed in the app are only on this device; keep them alongside the fetched history.
            let local = orders.filter { order in order.advancesAutomatically && !fetched.contains { $0.id == order.id } }
            orders = (local + fetched).sorted { $0.placedAt > $1.placedAt }
            state = .loaded
            persist()
            await refreshActiveTracking()
        } catch {
            state = orders.isEmpty ? .failed(message: APIError.message(for: error)) : .loaded
        }
    }

    // MARK: - Changing

    func place(_ request: OrderRequest) async throws -> Order {
        let order = try await service.placeOrder(request)
        orders.insert(order, at: 0)
        state = .loaded
        persist()
        return order
    }

    func cancel(orderID: String) async throws {
        guard let order = order(id: orderID) else {
            throw APIError.notFound
        }
        replace(try await service.cancelOrder(order))
    }

    /// Asks for the order's latest tracking status.
    func refreshTracking(orderID: String) async {
        guard let order = order(id: orderID), let updated = try? await service.trackOrder(order) else {
            return
        }
        replace(updated)
    }

    func refreshActiveTracking() async {
        for order in activeOrders {
            await refreshTracking(orderID: order.id)
        }
    }

    /// Forgets the order history on sign-out.
    func reset() {
        orders = []
        state = .idle
        persistence.remove(.orders)
    }

    // MARK: - Private

    private func replace(_ order: Order) {
        guard let index = orders.firstIndex(where: { $0.id == order.id }) else {
            return
        }
        orders[index] = order
        persist()
    }

    private func persist() {
        persistence.save(orders, for: .orders)
    }
}
