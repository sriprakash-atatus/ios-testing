/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

enum AppTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home
    case categories
    case wishlist
    case cart
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .categories: return "Categories"
        case .wishlist: return "Wishlist"
        case .cart: return "Cart"
        case .profile: return "Profile"
        }
    }

    var symbolName: String {
        switch self {
        case .home: return "house"
        case .categories: return "square.grid.2x2"
        case .wishlist: return "heart"
        case .cart: return "cart"
        case .profile: return "person"
        }
    }
}

/// Every screen that can be pushed onto a tab's navigation stack.
enum Route: Hashable, Sendable {
    case productList(ProductListContext)
    case product(id: String)
    case productReviews(productID: String)
    case search(query: String?)
    case wishlist
    case orders
    case orderDetail(orderID: String)
    case orderTracking(orderID: String)
    case editProfile
    case addresses
    case paymentMethods
    case notifications
    case settings
    case helpSupport
    case about
}

/// Screens presented full screen over the tabs.
enum AppCover: Identifiable, Hashable, Sendable {
    case auth
    case checkout(CheckoutSource)
    case orderSuccess(orderID: String)

    var id: String {
        switch self {
        case .auth: return "auth"
        case .checkout: return "checkout"
        case .orderSuccess(let orderID): return "order-success-\(orderID)"
        }
    }
}

/// The selected tab, each tab's navigation stack and the full-screen cover — all navigation state in
/// one place, so any screen or a deep link can move the app anywhere.
@MainActor
@Observable
final class AppRouter {
    static let urlScheme = "flipshop"

    var selectedTab: AppTab = .home
    var homePath: [Route] = []
    var categoriesPath: [Route] = []
    var wishlistPath: [Route] = []
    var cartPath: [Route] = []
    var profilePath: [Route] = []
    var cover: AppCover?

    func path(for tab: AppTab) -> [Route] {
        switch tab {
        case .home: return homePath
        case .categories: return categoriesPath
        case .wishlist: return wishlistPath
        case .cart: return cartPath
        case .profile: return profilePath
        }
    }

    func setPath(_ path: [Route], for tab: AppTab) {
        switch tab {
        case .home: homePath = path
        case .categories: categoriesPath = path
        case .wishlist: wishlistPath = path
        case .cart: cartPath = path
        case .profile: profilePath = path
        }
    }

    // MARK: - Tabs and stacks

    /// Selects `tab`; selecting the tab already showing pops it back to its root.
    func select(_ tab: AppTab) {
        if selectedTab == tab {
            popToRoot(tab)
        } else {
            selectedTab = tab
        }
    }

    /// Pushes `route` onto the selected tab's stack.
    func push(_ route: Route) {
        setPath(path(for: selectedTab) + [route], for: selectedTab)
    }

    /// Switches to `tab` and shows `route` directly above its root.
    func show(_ route: Route, in tab: AppTab) {
        selectedTab = tab
        setPath([route], for: tab)
    }

    func pop() {
        let current = path(for: selectedTab)
        guard !current.isEmpty else {
            return
        }
        setPath(Array(current.dropLast()), for: selectedTab)
    }

    func popToRoot(_ tab: AppTab? = nil) {
        setPath([], for: tab ?? selectedTab)
    }

    // MARK: - Covers

    func present(_ cover: AppCover) {
        self.cover = cover
    }

    func dismissCover() {
        cover = nil
    }

    func startCheckout(_ source: CheckoutSource) {
        cover = .checkout(source)
    }

    /// Replaces checkout with the order confirmation.
    func showOrderSuccess(orderID: String) {
        cover = .orderSuccess(orderID: orderID)
    }

    /// From the order confirmation: closes it and opens the order's tracking under Profile › Orders.
    func trackOrder(orderID: String) {
        cover = nil
        selectedTab = .profile
        profilePath = [.orders, .orderTracking(orderID: orderID)]
    }

    /// From the order confirmation: closes it and goes back to the home screen.
    func continueShopping() {
        cover = nil
        homePath = []
        selectedTab = .home
    }

    // MARK: - Deep links

    /// Opens a `flipshop://` or `https://flipshop.app/` link. Returns whether the link was understood.
    ///
    /// - `flipshop://product/{id}` and `flipshop://product/{id}/reviews`
    /// - `flipshop://category/{id}`, `flipshop://flash-sale`, `flipshop://search?q={query}`
    /// - `flipshop://cart`, `flipshop://wishlist`, `flipshop://orders` and `flipshop://orders/{id}`
    @discardableResult
    func handle(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        var segments = components.path.split(separator: "/").map(String.init)
        if components.scheme == AppRouter.urlScheme, let host = components.host {
            segments.insert(host, at: 0)
        }
        guard let first = segments.first else {
            return false
        }
        let argument = segments.count > 1 ? segments[1] : nil
        cover = nil

        switch first {
        case "product":
            guard let id = argument else {
                return false
            }
            show(.product(id: id), in: .home)
            if segments.count > 2 && segments[2] == "reviews" {
                homePath.append(.productReviews(productID: id))
            }
        case "category":
            guard let id = argument else {
                return false
            }
            show(.productList(ProductListContext(title: id.capitalized, source: .category(id: id))), in: .categories)
        case "flash-sale":
            show(.productList(.section(.flashSale)), in: .home)
        case "search":
            let query = components.queryItems?.first { $0.name == "q" }?.value
            show(.search(query: query), in: .home)
        case "cart":
            selectedTab = .cart
            cartPath = []
        case "wishlist":
            selectedTab = .wishlist
            wishlistPath = []
        case "orders":
            selectedTab = .profile
            profilePath = argument.map { [.orders, .orderDetail(orderID: $0)] } ?? [.orders]
        default:
            return false
        }
        return true
    }

    /// A link that opens `productID`, for sharing.
    static func shareURL(forProductID productID: String) -> URL? {
        URL(string: "https://flipshop.app/product/\(productID)")
    }
}
