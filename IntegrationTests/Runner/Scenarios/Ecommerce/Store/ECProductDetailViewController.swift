/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Product screen of the store in `AtatusEcommerceScenario`.

import UIKit

/// One product: price and offers, a delivery check by pincode, the wishlist heart, and the sticky
/// "Add to Cart | Buy Now" bar.
final class ECProductDetailViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private var product: ECProduct

    private var content = UIStackView()
    private let pincodeField = UITextField()
    private let deliveryLabel = ECStyle.label("Check the delivery date for your pincode", style: .footnote, color: .secondaryLabel)
    private lazy var wishlistButton = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(didTapWishlist))
    private lazy var addToCartButton = ECStyle.secondaryButton("Add to Cart", target: self, action: #selector(didTapAddToCart))
    private lazy var buyNowButton = ECStyle.primaryButton("Buy Now", target: self, action: #selector(didTapBuyNow))
    private var visit = 0

    init(store: ECStore, api: ECStoreAPI, product: ECProduct) {
        self.store = store
        self.api = api
        self.product = product
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = product.brand.isEmpty ? "Product" : product.brand
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Product Detail"

        wishlistButton.accessibilityIdentifier = "Wishlist"
        navigationItem.rightBarButtonItem = wishlistButton

        pincodeField.text = store.pincode
        pincodeField.placeholder = "Enter pincode"
        pincodeField.keyboardType = .numberPad
        pincodeField.borderStyle = .roundedRect
        pincodeField.delegate = self
        pincodeField.accessibilityIdentifier = "Pincode"

        let bar = ECStyle.bottomBar(in: view, arrangedSubviews: [addToCartButton, buyNowButton])
        content = ECStyle.scrollingColumn(in: view, arrangedSubviews: [], above: bar).1
        render()
        hideKeyboardWhenTapOutside()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The cart or wishlist may have changed on a screen pushed from here.
        updateWishlistButton()
        updateAddToCartButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        guard visit == 1 else {
            return
        }

        // Re-fetches the product the listing already showed. That second request is the point: it is
        // what a product screen does, and what the agent captures as this view's resource.
        api.loadProduct(id: product.id) { [weak self] fetched in
            guard let self = self, let fetched = fetched else {
                return
            }
            self.product = fetched
            self.render()
        }

        // The first product the shopper opens goes in the cart; later ones go on the wishlist, so
        // the wishlist has something to move to the cart further down the funnel.
        let putsInCart = store.isEmpty
        ECAutoPilot.step(after: 1.5) { [weak self] in self?.didTapCheckDelivery() }
        ECAutoPilot.step(after: 3.5) { [weak self] in
            guard let self = self else {
                return
            }
            if putsInCart {
                self.didTapAddToCart()
            } else if !self.store.isWishlisted(self.product) {
                self.didTapWishlist()
            }
        }
        ECAutoPilot.step(after: 5) { [weak self] in self?.flow?.returnToHome() }
    }

    // MARK: - Layout

    private func render() {
        let imageRow = UIStackView(arrangedSubviews: [ECStyle.productImage(for: product, side: 220)])
        imageRow.axis = .vertical
        imageRow.alignment = .center

        var summary: [UIView] = [imageRow]
        if !product.brand.isEmpty {
            summary.append(ECStyle.label(product.brand.uppercased(), style: .caption1, color: .secondaryLabel))
        }
        summary.append(ECStyle.label(product.title, style: .title3))
        if product.ratingCount > 0 {
            summary.append(ECStyle.ratingRow(for: product))
        }
        if product.discountPercent > 0 {
            summary.append(ECStyle.label("Special price", style: .caption1, color: ECStyle.offerGreen))
        }
        summary.append(ECStyle.priceRow(for: product, style: .title2))

        let pincodeRow = UIStackView(arrangedSubviews: [
            ECStyle.label("Deliver to", style: .subheadline),
            pincodeField,
            ECStyle.linkButton("Check", target: self, action: #selector(didTapCheckDelivery))
        ])
        pincodeRow.axis = .horizontal
        pincodeRow.spacing = 8
        pincodeRow.alignment = .center

        var sections: [UIView] = [
            ECStyle.card(summary),
            ECStyle.card([ECStyle.sectionHeader("Available offers")] + offerRows()),
            ECStyle.card([ECStyle.sectionHeader("Delivery"), pincodeRow, deliveryLabel])
        ]
        if !product.highlights.isEmpty {
            let bullets: [UIView] = product.highlights.map { ECStyle.label("•  \($0)", style: .subheadline) }
            sections.append(ECStyle.card([ECStyle.sectionHeader("Highlights")] + bullets))
        }
        sections.append(ECStyle.card([ECStyle.sectionHeader("Description"), ECStyle.label(product.description, style: .body, color: .secondaryLabel)]))

        ECStyle.replaceArrangedSubviews(of: content, with: sections)
    }

    private func offerRows() -> [UIView] {
        var offers = ["Bank Offer: 10% instant discount on SBI Credit Cards, up to ₹1,500"]
        if product.discountPercent > 0 {
            offers.append("Special Price: Get extra \(product.discountPercent)% off (price inclusive of discount)")
        }
        if product.price >= 3_000 {
            offers.append("No Cost EMI: from \(ECMoney.format((product.price / 6).rounded(.up)))/month")
        }
        offers.append("Partner Offer: Free 3 months of FlipShop Plus on this order")

        return offers.map { text -> UIView in
            let icon = UIImageView(image: UIImage(systemName: "tag.fill"))
            icon.tintColor = ECStyle.offerGreen
            icon.setContentHuggingPriority(.required, for: .horizontal)
            let row = UIStackView(arrangedSubviews: [icon, ECStyle.label(text, style: .subheadline)])
            row.axis = .horizontal
            row.spacing = 8
            row.alignment = .firstBaseline
            return row
        }
    }

    private func updateWishlistButton() {
        let isWishlisted = store.isWishlisted(product)
        wishlistButton.image = UIImage(systemName: isWishlisted ? "heart.fill" : "heart")
        wishlistButton.tintColor = isWishlisted ? UIColor.systemPink : nil
    }

    /// Once the product is in the cart, the button leads there instead of adding it again.
    private func updateAddToCartButton() {
        let title = store.contains(product) ? "Go to Cart" : "Add to Cart"
        addToCartButton.setTitle(title, for: .normal)
        addToCartButton.accessibilityIdentifier = title
    }

    // MARK: - Actions

    @objc
    private func didTapCheckDelivery() {
        let pincode = (pincodeField.text ?? "").trimmingCharacters(in: .whitespaces)
        pincodeField.resignFirstResponder()
        store.pincode = pincode
        deliveryLabel.text = "Checking delivery to \(pincode)…"
        deliveryLabel.textColor = .secondaryLabel

        api.checkDelivery(pincode: pincode, productID: product.id) { [weak self] estimate in
            guard let self = self else {
                return
            }
            guard let estimate = estimate else {
                let isValid = pincode.count == 6 && pincode.allSatisfy(\.isNumber)
                self.deliveryLabel.text = isValid ? "Could not check delivery right now" : "Please enter a valid 6-digit pincode"
                self.deliveryLabel.textColor = .systemRed
                return
            }
            let cashOnDelivery = estimate.deliverable && estimate.codAvailable ? "\nCash on Delivery available" : ""
            self.deliveryLabel.text = estimate.summary + cashOnDelivery
            self.deliveryLabel.textColor = estimate.deliverable ? .label : .systemRed
        }
    }

    @objc
    private func didTapWishlist() {
        let isWishlisted = store.toggleWishlist(product)
        updateWishlistButton()
        if isWishlisted {
            api.addToWishlist(productID: product.id) {}
        } else {
            api.removeFromWishlist(productID: product.id) {}
        }
    }

    @objc
    private func didTapAddToCart() {
        // The auto pilot and a real tap can both reach this; the cart must not gain the product twice.
        guard !store.contains(product) else {
            flow?.showCart()
            return
        }
        addToCart()
    }

    /// Buy Now skips the "added" state and goes straight to the cart with the product in it.
    @objc
    private func didTapBuyNow() {
        if !store.contains(product) {
            addToCart()
        }
        flow?.showCart()
    }

    private func addToCart() {
        store.add(product)
        updateAddToCartButton()
        deliveryLabel.text = "Added to cart — \(store.itemCount) item(s)"
        deliveryLabel.textColor = ECStyle.offerGreen
        api.addToCart(productID: product.id, quantity: 1) {}
    }
}

extension ECProductDetailViewController: UITextFieldDelegate {
    /// Pincodes are six digits; anything else never reaches the field.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = (textField.text ?? "") as NSString
        let updated = current.replacingCharacters(in: range, with: string)
        return updated.count <= 6 && updated.allSatisfy(\.isNumber)
    }
}
