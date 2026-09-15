/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// Home · Categories · Wishlist · Cart · Profile, each with its own navigation stack driven by `AppRouter`.
struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(CartStore.self) private var cart
    @Environment(WishlistStore.self) private var wishlist

    var body: some View {
        @Bindable var router = router

        TabView(selection: tabSelection) {
            NavigationStack(path: $router.homePath) {
                HomeView()
                    .routeDestinations()
            }
            .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.symbolName) }
            .tag(AppTab.home)

            NavigationStack(path: $router.categoriesPath) {
                CategoriesView()
                    .routeDestinations()
            }
            .tabItem { Label(AppTab.categories.title, systemImage: AppTab.categories.symbolName) }
            .tag(AppTab.categories)

            NavigationStack(path: $router.wishlistPath) {
                WishlistView()
                    .routeDestinations()
            }
            .tabItem { Label(AppTab.wishlist.title, systemImage: AppTab.wishlist.symbolName) }
            .badge(wishlist.count)
            .tag(AppTab.wishlist)

            NavigationStack(path: $router.cartPath) {
                CartView()
                    .routeDestinations()
            }
            .tabItem { Label(AppTab.cart.title, systemImage: AppTab.cart.symbolName) }
            .badge(cart.itemCount)
            .tag(AppTab.cart)

            NavigationStack(path: $router.profilePath) {
                ProfileView()
                    .routeDestinations()
            }
            .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.symbolName) }
            .tag(AppTab.profile)
        }
        .tint(Color.brand)
        .sensoryFeedback(.selection, trigger: router.selectedTab)
    }

    /// Goes through `AppRouter.select(_:)`, so tapping the current tab pops it to its root.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { router.selectedTab },
            set: { router.select($0) }
        )
    }
}

extension View {
    /// Registers every `Route` as a navigation destination. Apply to the root view of each `NavigationStack`.
    func routeDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            RouteDestinationView(route: route)
        }
    }
}

/// The screen for each `Route`.
struct RouteDestinationView: View {
    let route: Route

    var body: some View {
        switch route {
        case .productList(let context):
            ProductListingView(context: context)
        case .product(let id):
            ProductDetailView(productID: id)
        case .productReviews(let productID):
            ProductReviewsView(productID: productID)
        case .search(let query):
            SearchView(initialQuery: query)
        case .wishlist:
            WishlistView()
        case .orders:
            OrdersView()
        case .orderDetail(let orderID):
            OrderDetailView(orderID: orderID)
        case .orderTracking(let orderID):
            OrderTrackingView(orderID: orderID)
        case .editProfile:
            EditProfileView()
        case .addresses:
            AddressesView()
        case .paymentMethods:
            PaymentMethodsView()
        case .notifications:
            NotificationSettingsView()
        case .settings:
            SettingsView()
        case .helpSupport:
            HelpSupportView()
        case .about:
            AboutView()
        }
    }
}

/// The screen for each full-screen `AppCover`.
struct AppCoverView: View {
    let cover: AppCover

    var body: some View {
        switch cover {
        case .auth:
            AuthFlowView(isDismissable: true)
        case .checkout(let source):
            CheckoutFlowView(source: source)
        case .orderSuccess(let orderID):
            OrderSuccessView(orderID: orderID)
        }
    }
}
