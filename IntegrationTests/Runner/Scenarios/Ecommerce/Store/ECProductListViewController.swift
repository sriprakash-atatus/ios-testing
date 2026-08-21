/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: First screen of the store in `AtatusEcommerceScenario`.

import UIKit

/// The catalog. Lists the products the store API returns, and holds the cart button the funnel
/// exits through.
final class ECProductListViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private var products: [ECProduct] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let cartButton = UIBarButtonItem()

    /// Which time the shopper is looking at the catalog. The auto pilot browses twice, then leaves
    /// for the cart, and this is what tells those visits apart.
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

        title = "Atatus Store"
        view.backgroundColor = .systemBackground

        cartButton.target = self
        cartButton.action = #selector(didTapCart)
        cartButton.accessibilityIdentifier = "Cart"
        navigationItem.rightBarButtonItem = cartButton
        updateCartButton()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.accessibilityIdentifier = "Product List"
        tableView.register(ECProductCell.self, forCellReuseIdentifier: ECProductCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        updateCartButton()

        switch visit {
        case 1:
            api.loadCatalog { [weak self] products in
                self?.products = products
                self?.tableView.reloadData()
            }
            ECAutoPilot.step(after: 3) { [weak self] in self?.select(at: 0) }
        case 2:
            // Second pass through the catalog, further down the list — a scroll the replay shows.
            ECAutoPilot.step(after: 1.2) { [weak self] in self?.scrollToEnd() }
            ECAutoPilot.step(after: 2.6) { [weak self] in self?.select(at: 2) }
        default:
            ECAutoPilot.step(after: 1.5) { [weak self] in self?.didTapCart() }
        }
    }

    // MARK: - Navigation

    private func scrollToEnd() {
        guard !products.isEmpty else {
            return
        }
        tableView.scrollToRow(at: IndexPath(row: products.count - 1, section: 0), at: .bottom, animated: true)
    }

    private func select(at index: Int) {
        guard products.indices.contains(index) else {
            return
        }
        tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .middle)
        flow?.showProduct(products[index])
    }

    @objc
    private func didTapCart() {
        guard !store.isEmpty else {
            return
        }
        flow?.showCart()
    }

    private func updateCartButton() {
        cartButton.title = store.isEmpty ? "Cart" : "Cart (\(store.itemCount))"
    }
}

// MARK: - Table

extension ECProductListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ECProductCell.reuseIdentifier, for: indexPath)
        (cell as? ECProductCell)?.show(products[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        select(at: indexPath.row)
    }
}

/// A catalog row: title, category and price.
private final class ECProductCell: UITableViewCell {
    static let reuseIdentifier = "ECProductCell"

    private let titleLabel = ECStyle.label("", style: .headline)
    private let categoryLabel = ECStyle.label("", style: .subheadline, color: .secondaryLabel)
    private let priceLabel = ECStyle.label("", style: .headline, color: ECStyle.accent)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.numberOfLines = 2
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let text = UIStackView(arrangedSubviews: [titleLabel, categoryLabel])
        text.axis = .vertical
        text.spacing = 4

        let row = UIStackView(arrangedSubviews: [text, priceLabel])
        row.axis = .horizontal
        row.spacing = ECStyle.spacing
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    func show(_ product: ECProduct) {
        titleLabel.text = product.title
        categoryLabel.text = product.category.uppercased()
        priceLabel.text = product.formattedPrice
        accessibilityIdentifier = "product-\(product.id)"
    }
}
