/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// Builds every service and store once, at launch, and hands them to the view hierarchy.
@MainActor
final class AppContainer {
    let services: AppServices
    let catalog: CatalogStore
    let cart: CartStore
    let wishlist: WishlistStore
    let session: SessionStore
    let account: AccountStore
    let orders: OrderStore
    let search: SearchStore
    let router: AppRouter
    let toasts: ToastCenter

    init(services: AppServices = .mock) {
        self.services = services
        catalog = CatalogStore(service: services.products)
        cart = CartStore(service: services.cart)
        wishlist = WishlistStore()
        session = SessionStore(service: services.auth, userService: services.users)
        account = AccountStore(service: services.users)
        orders = OrderStore(service: services.orders)
        search = SearchStore(service: services.search)
        router = AppRouter()
        toasts = ToastCenter()
    }
}

extension View {
    /// Puts every store in the environment, where screens read them with `@Environment(CartStore.self)`
    /// and friends, and the services under `\.appServices`.
    func injectDependencies(_ container: AppContainer) -> some View {
        self
            .environment(container.catalog)
            .environment(container.cart)
            .environment(container.wishlist)
            .environment(container.session)
            .environment(container.account)
            .environment(container.orders)
            .environment(container.search)
            .environment(container.router)
            .environment(container.toasts)
            .environment(\.appServices, container.services)
    }
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue = AppServices.mock
}

extension EnvironmentValues {
    /// The services, for screens that create their own store — checkout creates a `CheckoutStore`
    /// with `appServices.payments`.
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
