/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Root of the store in `AtatusEcommerceScenario`. Owns the cart and the API client every
// screen shares.

import UIKit

/// Drives the shopping funnel: catalog → product → cart → checkout → order confirmation.
///
/// Instantiated from `AtatusEcommerceScenario.storyboard`, which holds nothing but this navigation
/// controller — every screen is built in code, so the funnel reads top to bottom here rather than
/// across a storyboard's segues.
final class ECStoreNavigationController: UINavigationController {
    /// The cart every screen in the funnel reads and writes.
    let store = ECStore()

    /// The store's backend. Shared, so one instrumented `URLSession` serves the whole funnel.
    let api = ECStoreAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = ECStyle.accent
        view.backgroundColor = .systemBackground

        setViewControllers([ECProductListViewController(store: store, api: api)], animated: false)
    }

    // MARK: - Funnel

    func showProduct(_ product: ECProduct) {
        pushViewController(ECProductDetailViewController(store: store, api: api, product: product), animated: true)
    }

    func showCart() {
        pushViewController(ECCartViewController(store: store), animated: true)
    }

    func showCheckout() {
        pushViewController(ECCheckoutViewController(store: store, api: api), animated: true)
    }

    func showOrderConfirmation() {
        let confirmation = ECOrderConfirmationViewController(store: store)
        // The order is placed: leaving checkout on the stack would let a back tap re-enter a funnel
        // that is already finished.
        setViewControllers([viewControllers[0], confirmation], animated: true)
    }

    func returnToCatalog() {
        popToRootViewController(animated: true)
    }
}
