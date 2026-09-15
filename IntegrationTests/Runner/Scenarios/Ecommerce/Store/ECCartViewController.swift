/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Cart and wishlist screens of the store in `AtatusEcommerceScenario`.

import UIKit

// MARK: - Cart

/// What is in the cart and what it costs: a card per line with a quantity stepper, the price
/// breakdown with the discount taken off the MRP, and the way to checkout.
final class ECCartViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private var scrollView = UIScrollView()
    private var content = UIStackView()
    private let totalLabel = ECStyle.label("", style: .title3)
    private lazy var placeOrderButton = ECStyle.primaryButton("Place Order", target: self, action: #selector(didTapPlaceOrder))
    private var hasStartedCheckout = false
    private var visit = 0

    init(store: ECStore, api: ECStoreAPI) {
        self.store = store
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Cart"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Cart"

        totalLabel.font = .preferredFont(forTextStyle: .title3).bold()
        let total = UIStackView(arrangedSubviews: [
            totalLabel,
            ECStyle.linkButton("View price details", target: self, action: #selector(didTapPriceDetails))
        ])
        total.axis = .vertical
        total.alignment = .leading

        let bar = ECStyle.bottomBar(in: view, arrangedSubviews: [total, placeOrderButton])
        (scrollView, content) = ECStyle.scrollingColumn(in: view, arrangedSubviews: [], above: bar)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Back from the address step, the shopper may place the order again.
        hasStartedCheckout = false
        render()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        guard visit == 1 else {
            return
        }
        ECAutoPilot.step(after: 2) { [weak self] in self?.increaseQuantity(ofLineAt: 0) }
        ECAutoPilot.step(after: 4.5) { [weak self] in self?.didTapPlaceOrder() }
    }

    // MARK: - Layout

    private func render() {
        totalLabel.text = ECMoney.format(store.total)
        placeOrderButton.isEnabled = !store.isEmpty
        placeOrderButton.alpha = store.isEmpty ? 0.5 : 1

        guard !store.isEmpty else {
            ECStyle.replaceArrangedSubviews(of: content, with: [emptyState()])
            return
        }

        let deliverTo = ECStyle.label("Deliver to: \(store.address.name), \(store.address.pincode)", style: .subheadline)
        var sections: [UIView] = [ECStyle.card([deliverTo])]
        sections += store.lines.map(lineCard)
        sections.append(priceDetails())
        ECStyle.replaceArrangedSubviews(of: content, with: sections)
    }

    private func lineCard(_ line: ECCartLine) -> UIView {
        let productID = line.product.id

        let decrease = stepperButton("−", identifier: "decrease-\(productID)", action: #selector(didTapDecrease(_:)))
        decrease.tag = productID
        decrease.isEnabled = line.quantity > 1
        let increase = stepperButton("+", identifier: "increase-\(productID)", action: #selector(didTapIncrease(_:)))
        increase.tag = productID
        increase.isEnabled = line.quantity < ECStore.maximumQuantity

        let quantity = ECStyle.label("\(line.quantity)", style: .headline)
        quantity.textAlignment = .center
        quantity.widthAnchor.constraint(equalToConstant: 32).isActive = true

        let stepper = UIStackView(arrangedSubviews: [decrease, quantity, increase])
        stepper.axis = .horizontal
        stepper.spacing = 4
        stepper.alignment = .center

        let saveForLater = ECStyle.linkButton("Save for later", color: .label, target: self, action: #selector(didTapSaveForLater(_:)))
        saveForLater.tag = productID
        saveForLater.accessibilityIdentifier = "save-for-later-\(productID)"
        let remove = ECStyle.linkButton("Remove", color: .label, target: self, action: #selector(didTapRemove(_:)))
        remove.tag = productID
        remove.accessibilityIdentifier = "remove-\(productID)"

        let actions = UIStackView(arrangedSubviews: [stepper, UIView(), saveForLater, remove])
        actions.axis = .horizontal
        actions.spacing = ECStyle.spacing
        actions.alignment = .center

        return ECStyle.card([ECStoreLayout.productRow(line.product, imageSide: 72), actions], spacing: 12)
    }

    private func stepperButton(_ title: String, identifier: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        button.layer.borderColor = UIColor.separator.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 16
        button.accessibilityIdentifier = identifier
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        return button
    }

    private func priceDetails() -> UIView {
        var rows: [UIView] = [
            ECStyle.label("PRICE DETAILS", style: .subheadline, color: .secondaryLabel),
            ECStyle.amountRow("Price (\(store.itemCount) item\(store.itemCount == 1 ? "" : "s"))", ECMoney.format(store.mrpTotal))
        ]
        if store.discount > 0 {
            rows.append(ECStyle.amountRow("Discount", "− \(ECMoney.format(store.discount))", color: ECStyle.offerGreen))
        }
        let isFreeDelivery = store.deliveryFee == 0
        rows.append(ECStyle.amountRow("Delivery Charges", isFreeDelivery ? "FREE" : ECMoney.format(store.deliveryFee), color: isFreeDelivery ? ECStyle.offerGreen : .label))
        rows.append(ECStyle.separator())
        rows.append(ECStyle.amountRow("Total Amount", ECMoney.format(store.total), emphasised: true))
        if store.discount > 0 {
            rows.append(ECStyle.separator())
            rows.append(ECStyle.label("You will save \(ECMoney.format(store.discount)) on this order", style: .subheadline, color: ECStyle.offerGreen))
        }
        return ECStyle.card(rows, spacing: 10)
    }

    private func emptyState() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "cart"))
        icon.tintColor = ECStyle.brandBlue
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let title = ECStyle.label("Your cart is empty!", style: .title3)
        title.textAlignment = .center
        let subtitle = ECStyle.label("Add items to it now.", style: .subheadline, color: .secondaryLabel)
        subtitle.textAlignment = .center

        return ECStyle.card([icon, title, subtitle, ECStyle.primaryButton("Shop Now", target: self, action: #selector(didTapShopNow))], spacing: 12)
    }

    // MARK: - Actions

    @objc
    private func didTapIncrease(_ sender: UIButton) {
        changeQuantity(ofProductID: sender.tag, by: 1)
    }

    @objc
    private func didTapDecrease(_ sender: UIButton) {
        changeQuantity(ofProductID: sender.tag, by: -1)
    }

    private func increaseQuantity(ofLineAt index: Int) {
        guard store.lines.indices.contains(index) else {
            return
        }
        changeQuantity(ofProductID: store.lines[index].product.id, by: 1)
    }

    private func changeQuantity(ofProductID productID: Int, by delta: Int) {
        guard let line = store.lines.first(where: { $0.product.id == productID }) else {
            return
        }
        let wanted = line.quantity + delta
        guard wanted >= 1, wanted <= ECStore.maximumQuantity else {
            return
        }
        let applied = store.setQuantity(wanted, forProductID: productID)
        render()
        api.updateCartItem(productID: productID, quantity: applied) {}
    }

    @objc
    private func didTapRemove(_ sender: UIButton) {
        store.removeFromCart(productID: sender.tag)
        render()
        api.removeFromCart(productID: sender.tag) {}
    }

    /// Moves the line to the wishlist, which is where "saved for later" items wait.
    @objc
    private func didTapSaveForLater(_ sender: UIButton) {
        guard let line = store.lines.first(where: { $0.product.id == sender.tag }) else {
            return
        }
        store.removeFromCart(productID: line.product.id)
        api.removeFromCart(productID: line.product.id) {}
        if !store.isWishlisted(line.product) {
            store.toggleWishlist(line.product)
            api.addToWishlist(productID: line.product.id) {}
        }
        render()
    }

    @objc
    private func didTapPriceDetails() {
        let bottom = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        scrollView.setContentOffset(CGPoint(x: 0, y: max(bottom, -scrollView.adjustedContentInset.top)), animated: true)
    }

    @objc
    private func didTapShopNow() {
        flow?.returnToHome()
    }

    @objc
    private func didTapPlaceOrder() {
        guard !store.isEmpty, !hasStartedCheckout else {
            return
        }
        hasStartedCheckout = true
        flow?.showAddress()
    }
}

// MARK: - Wishlist

/// Products the shopper hearted, each one a tap away from the cart.
final class ECWishlistViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private var content = UIStackView()
    private lazy var cartButton = cartBarButton(store: store, action: #selector(didTapCart))
    private var visit = 0

    init(store: ECStore, api: ECStoreAPI) {
        self.store = store
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = cartButton
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Wishlist"
        content = ECStyle.scrollingColumn(in: view, arrangedSubviews: []).1
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        guard visit == 1 else {
            return
        }
        ECAutoPilot.step(after: 2) { [weak self] in self?.moveToCart(at: 0) }
        ECAutoPilot.step(after: 3.5) { [weak self] in self?.didTapCart() }
    }

    // MARK: - Layout

    private func render() {
        title = store.wishlist.isEmpty ? "My Wishlist" : "My Wishlist (\(store.wishlist.count))"
        cartButton.title = cartTitle(store: store)

        guard !store.wishlist.isEmpty else {
            let icon = UIImageView(image: UIImage(systemName: "heart"))
            icon.tintColor = .systemPink
            icon.contentMode = .scaleAspectFit
            icon.heightAnchor.constraint(equalToConstant: 64).isActive = true
            let message = ECStyle.label("Your wishlist is empty.\nTap the heart on a product to save it here.", style: .body, color: .secondaryLabel)
            message.textAlignment = .center
            ECStyle.replaceArrangedSubviews(of: content, with: [ECStyle.card([icon, message], spacing: 12)])
            return
        }

        let cards = store.wishlist.enumerated().map { index, product -> UIView in
            let summary = ECTapTile(content: ECStoreLayout.productRow(product, imageSide: 72), identifier: "wishlist-\(product.id)")
            summary.tag = index
            summary.addTarget(self, action: #selector(didTapProduct(_:)), for: .touchUpInside)

            let moveToCart = ECStyle.linkButton("Move to Cart", target: self, action: #selector(didTapMoveToCart(_:)))
            moveToCart.tag = index
            moveToCart.accessibilityIdentifier = "move-to-cart-\(product.id)"
            let remove = ECStyle.linkButton("Remove", color: .secondaryLabel, target: self, action: #selector(didTapRemove(_:)))
            remove.tag = index
            remove.accessibilityIdentifier = "remove-\(product.id)"

            let actions = UIStackView(arrangedSubviews: [moveToCart, UIView(), remove])
            actions.axis = .horizontal
            actions.alignment = .center

            return ECStyle.card([summary, actions], spacing: 12)
        }
        ECStyle.replaceArrangedSubviews(of: content, with: cards)
    }

    // MARK: - Actions

    @objc
    private func didTapProduct(_ sender: UIControl) {
        guard store.wishlist.indices.contains(sender.tag) else {
            return
        }
        flow?.showProduct(store.wishlist[sender.tag])
    }

    @objc
    private func didTapMoveToCart(_ sender: UIButton) {
        moveToCart(at: sender.tag)
    }

    private func moveToCart(at index: Int) {
        guard store.wishlist.indices.contains(index) else {
            return
        }
        let product = store.wishlist[index]
        store.add(product)
        store.removeFromWishlist(productID: product.id)
        render()
        api.addToCart(productID: product.id, quantity: 1) {}
        api.removeFromWishlist(productID: product.id) {}
    }

    @objc
    private func didTapRemove(_ sender: UIButton) {
        guard store.wishlist.indices.contains(sender.tag) else {
            return
        }
        let product = store.wishlist[sender.tag]
        store.removeFromWishlist(productID: product.id)
        render()
        api.removeFromWishlist(productID: product.id) {}
    }

    @objc
    private func didTapCart() {
        guard !store.isEmpty else {
            return
        }
        flow?.showCart()
    }
}

// MARK: - Shared layout

enum ECStoreLayout {
    /// A product's photo beside its brand, title, rating and price — the head of every cart and
    /// wishlist card.
    static func productRow(_ product: ECProduct, imageSide: CGFloat) -> UIView {
        let title = ECStyle.label(product.title, style: .body)
        title.numberOfLines = 2

        var lines: [UIView] = []
        if !product.brand.isEmpty {
            lines.append(ECStyle.label(product.brand.uppercased(), style: .caption1, color: .secondaryLabel))
        }
        lines.append(title)
        if product.ratingCount > 0 {
            lines.append(ECStyle.ratingRow(for: product))
        }
        lines.append(ECStyle.priceRow(for: product, style: .headline))

        let details = UIStackView(arrangedSubviews: lines)
        details.axis = .vertical
        details.spacing = 4

        let row = UIStackView(arrangedSubviews: [ECStyle.productImage(for: product, side: imageSide), details])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        return row
    }
}
