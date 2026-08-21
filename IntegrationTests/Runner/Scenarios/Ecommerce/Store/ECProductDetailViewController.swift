/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Product screen of the store in `AtatusEcommerceScenario`.

import UIKit

/// One product, and the button that puts it in the cart.
final class ECProductDetailViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private var product: ECProduct

    private let titleLabel: UILabel
    private let priceLabel: UILabel
    private let descriptionLabel: UILabel
    private let statusLabel = ECStyle.label("Loading…", style: .footnote, color: .secondaryLabel)
    private var hasAddedToCart = false

    init(store: ECStore, api: ECStoreAPI, product: ECProduct) {
        self.store = store
        self.api = api
        self.product = product
        titleLabel = ECStyle.label(product.title, style: .title1)
        priceLabel = ECStyle.label(product.formattedPrice, style: .title2, color: ECStyle.accent)
        descriptionLabel = ECStyle.label(product.description, style: .body, color: .secondaryLabel)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = product.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "Product Detail"

        ECStyle.column(in: view, arrangedSubviews: [
            ECStyle.label(product.category.uppercased(), style: .caption1, color: .secondaryLabel),
            titleLabel,
            priceLabel,
            descriptionLabel,
            ECStyle.primaryButton("Add to Cart", target: self, action: #selector(didTapAddToCart)),
            statusLabel
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Re-fetches the product the catalog already listed. That second request is the point: it is
        // what a product screen does, and what the agent captures as this view's resource.
        api.loadProduct(id: product.id) { [weak self] fetched in
            guard let self = self else {
                return
            }
            if let fetched = fetched {
                self.product = fetched
                self.titleLabel.text = fetched.title
                self.priceLabel.text = fetched.formattedPrice
                self.descriptionLabel.text = fetched.description
            }
            self.statusLabel.text = "In stock — ships in 2 days"
        }

        ECAutoPilot.step(after: 2.5) { [weak self] in self?.didTapAddToCart() }
        ECAutoPilot.step(after: 4) { [weak self] in self?.flow?.returnToCatalog() }
    }

    // MARK: - Actions

    @objc
    private func didTapAddToCart() {
        // The auto pilot and a real tap can both reach this; the cart must not gain the product twice.
        guard !hasAddedToCart else {
            return
        }
        hasAddedToCart = true

        store.add(product)
        statusLabel.text = "Adding to cart…"

        api.addToCart(productID: product.id, quantity: 1) { [weak self] in
            guard let self = self else {
                return
            }
            self.statusLabel.text = "Added to cart — \(self.store.itemCount) item(s)"
        }
    }
}
