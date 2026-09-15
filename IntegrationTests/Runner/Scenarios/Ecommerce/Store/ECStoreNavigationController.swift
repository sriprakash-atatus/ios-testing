/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Root of the store in `AtatusEcommerceScenario`. Owns the cart and the API client every
// screen shares.

import UIKit

/// Drives the shopping funnel:
///
///     home → search → results → product → home → category → product (wishlisted) → home
///          → wishlist → cart → address → payment → order confirmation
///
/// Instantiated from `AtatusEcommerceScenario.storyboard`, which holds nothing but this navigation
/// controller — every screen is built in code, so the funnel reads top to bottom here rather than
/// across a storyboard's segues.
final class ECStoreNavigationController: UINavigationController {
    /// The cart, wishlist and checkout choices every screen in the funnel reads and writes.
    let store = ECStore()

    /// The store's backend. Shared, so one instrumented `URLSession` serves the whole funnel.
    let api = ECStoreAPI()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()

        // The marketplace's blue header, white titles and buttons.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ECStyle.brandBlue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.prefersLargeTitles = false
        navigationBar.barStyle = .black
        navigationBar.tintColor = .white
        view.backgroundColor = ECStyle.pageBackground

        setViewControllers([ECHomeViewController(store: store, api: api)], animated: false)
    }

    // MARK: - Discovery

    func showSearch() {
        pushViewController(ECSearchViewController(store: store, api: api), animated: true)
    }

    func showListing(for source: ECProductListViewController.Source) {
        pushViewController(ECProductListViewController(store: store, api: api, source: source), animated: true)
    }

    func showProduct(_ product: ECProduct) {
        pushViewController(ECProductDetailViewController(store: store, api: api, product: product), animated: true)
    }

    func showWishlist() {
        pushViewController(ECWishlistViewController(store: store, api: api), animated: true)
    }

    // MARK: - Checkout

    func showCart() {
        pushViewController(ECCartViewController(store: store, api: api), animated: true)
    }

    func showAddress() {
        pushViewController(ECAddressViewController(store: store, api: api), animated: true)
    }

    func showPayment() {
        pushViewController(ECCheckoutViewController(store: store, api: api), animated: true)
    }

    func showOrderConfirmation() {
        let confirmation = ECOrderConfirmationViewController(store: store, api: api)
        // The order is placed: leaving checkout on the stack would let a back tap re-enter a funnel
        // that is already finished.
        let home = viewControllers.first.map { [$0] } ?? []
        setViewControllers(home + [confirmation], animated: true)
    }

    func returnToHome() {
        popToRootViewController(animated: true)
    }
}
