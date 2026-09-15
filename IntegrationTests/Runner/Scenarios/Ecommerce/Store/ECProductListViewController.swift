/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Discovery screens of the store in `AtatusEcommerceScenario` — the home feed, search with
// autocomplete, and the product listing both of them lead to.

import UIKit

// MARK: - Home

/// The home feed: search box, category strip, offer carousel and "Deals of the Day". First screen of
/// the store, and the one the funnel returns to between products.
final class ECHomeViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI

    private var categories: [ECCategory] = []
    private var offers: [ECOffer] = []
    private var deals: [ECProduct] = []

    private let categoryStrip = UIStackView()
    private let bannerScrollView = UIScrollView()
    private let bannerStack = UIStackView()
    private let pageControl = UIPageControl()
    private let dealsGrid = UIStackView()
    private var bannerTimer: Timer?
    private lazy var cartButton = cartBarButton(store: store, action: #selector(didTapCart))

    /// Which time the shopper is looking at the home feed. The auto pilot searches on the first visit,
    /// browses a category on the second, opens the wishlist on the third, then leaves for the cart.
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

        title = "FlipShop"
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Home"

        let wishlistButton = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(didTapWishlist))
        wishlistButton.accessibilityIdentifier = "Wishlist"
        navigationItem.rightBarButtonItems = [cartButton, wishlistButton]

        categoryStrip.axis = .horizontal
        categoryStrip.spacing = 12
        categoryStrip.alignment = .top

        dealsGrid.axis = .vertical
        dealsGrid.spacing = 8

        ECStyle.scrollingColumn(in: view, arrangedSubviews: [
            searchBox(),
            ECStyle.card([horizontallyScrolling(categoryStrip)]),
            bannerCarousel(),
            ECStyle.card([ECStyle.sectionHeader("Deals of the Day"), dealsGrid], spacing: 12)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        cartButton.title = cartTitle(store: store)
        startBannerTimer()

        switch visit {
        case 1:
            loadFeed()
            ECAutoPilot.step(after: 3) { [weak self] in self?.didTapSearch() }
        case 2:
            ECAutoPilot.step(after: 1) { [weak self] in self?.showNextBanner() }
            // Electronics: a different department from the one the search landed in.
            ECAutoPilot.step(after: 2.5) { [weak self] in self?.openCategory(at: 1) }
        case 3:
            ECAutoPilot.step(after: 1.5) { [weak self] in self?.didTapWishlist() }
        default:
            ECAutoPilot.step(after: 1.5) { [weak self] in self?.didTapCart() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bannerTimer?.invalidate()
        bannerTimer = nil
    }

    // MARK: - Feed

    /// Three requests at once, as a real home feed makes them — each section fills in as its own
    /// response arrives.
    private func loadFeed() {
        api.loadCategories { [weak self] categories in
            self?.categories = categories
            self?.showCategories()
        }
        api.loadOffers { [weak self] offers in
            self?.offers = offers
            self?.showOffers()
        }
        api.loadDeals { [weak self] deals in
            self?.deals = deals
            self?.showDeals()
        }
    }

    private func showCategories() {
        let tiles = categories.enumerated().map { index, category -> UIView in
            let icon = UIImageView(image: UIImage(systemName: category.icon))
            icon.tintColor = ECStyle.brandBlue
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false

            let circle = UIView()
            circle.backgroundColor = ECStyle.brandBlue.withAlphaComponent(0.1)
            circle.layer.cornerRadius = 28
            circle.addSubview(icon)
            circle.translatesAutoresizingMaskIntoConstraints = false

            let name = ECStyle.label(category.name, style: .caption1)
            name.textAlignment = .center

            let column = UIStackView(arrangedSubviews: [circle, name])
            column.axis = .vertical
            column.spacing = 6
            column.alignment = .center

            NSLayoutConstraint.activate([
                circle.widthAnchor.constraint(equalToConstant: 56),
                circle.heightAnchor.constraint(equalToConstant: 56),
                icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 28),
                icon.heightAnchor.constraint(equalToConstant: 28),
                column.widthAnchor.constraint(equalToConstant: 72)
            ])

            let tile = ECTapTile(content: column, identifier: "category-\(category.id)")
            tile.tag = index
            tile.addTarget(self, action: #selector(didTapCategory(_:)), for: .touchUpInside)
            return tile
        }
        ECStyle.replaceArrangedSubviews(of: categoryStrip, with: tiles)
    }

    private func showOffers() {
        let colors = [ECStyle.brandBlue, ECStyle.buyNowOrange, UIColor.systemPurple]
        let banners = offers.enumerated().map { index, offer -> UIView in
            let title = ECStyle.label(offer.title, style: .title2, color: .white)
            title.font = .preferredFont(forTextStyle: .title2).bold()
            let content = UIStackView(arrangedSubviews: [
                title,
                ECStyle.label(offer.subtitle, style: .subheadline, color: .white),
                ECStyle.label("Shop now ›", style: .headline, color: ECStyle.brandYellow)
            ])
            content.axis = .vertical
            content.spacing = 6
            content.alignment = .leading

            let banner = ECTapTile(content: content, identifier: "offer-\(offer.id)", insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
            banner.backgroundColor = colors[index % colors.count]
            banner.tag = index
            banner.addTarget(self, action: #selector(didTapOffer(_:)), for: .touchUpInside)
            return banner
        }
        ECStyle.replaceArrangedSubviews(of: bannerStack, with: banners)
        // Each banner is exactly one page wide, so paging lands on banner boundaries.
        banners.forEach { $0.widthAnchor.constraint(equalTo: bannerScrollView.widthAnchor).isActive = true }
        pageControl.numberOfPages = offers.count
        pageControl.currentPage = 0
    }

    private func showDeals() {
        let tiles = deals.enumerated().map { index, product -> UIView in
            let title = ECStyle.label(product.title, style: .subheadline)
            title.numberOfLines = 2
            title.textAlignment = .center

            let price = ECStyle.label(product.formattedPrice, style: .headline)
            price.textAlignment = .center

            let discount = ECStyle.label(product.discountPercent > 0 ? "\(product.discountPercent)% off" : " ", style: .subheadline, color: ECStyle.offerGreen)
            discount.textAlignment = .center

            let column = UIStackView(arrangedSubviews: [ECStyle.productImage(for: product, side: 96), title, price, discount])
            column.axis = .vertical
            column.spacing = 4
            column.alignment = .center

            let tile = ECTapTile(content: column, identifier: "deal-\(product.id)", insets: UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4))
            tile.layer.borderColor = UIColor.separator.cgColor
            tile.layer.borderWidth = 1
            tile.layer.cornerRadius = 6
            tile.tag = index
            tile.addTarget(self, action: #selector(didTapDeal(_:)), for: .touchUpInside)
            return tile
        }

        // Two to a row; an odd last tile keeps half the width rather than stretching across.
        let rows = stride(from: 0, to: tiles.count, by: 2).map { start -> UIView in
            let pair = Array(tiles[start..<min(start + 2, tiles.count)])
            let row = UIStackView(arrangedSubviews: pair.count == 2 ? pair : pair + [UIView()])
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            return row
        }
        ECStyle.replaceArrangedSubviews(of: dealsGrid, with: rows)
    }

    // MARK: - Layout

    /// A search box that is really a button: the home feed has no keyboard, the search screen does.
    private func searchBox() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .secondaryLabel
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [icon, ECStyle.label("Search for products, brands and more", style: .body, color: .secondaryLabel)])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center

        let box = ECTapTile(content: row, identifier: "Search", insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        box.backgroundColor = .secondarySystemGroupedBackground
        box.layer.cornerRadius = 6
        box.layer.borderColor = ECStyle.brandBlue.cgColor
        box.layer.borderWidth = 1
        box.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        return box
    }

    private func horizontallyScrolling(_ stack: UIStackView) -> UIView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 84)
        ])
        return scrollView
    }

    private func bannerCarousel() -> UIView {
        bannerScrollView.isPagingEnabled = true
        bannerScrollView.showsHorizontalScrollIndicator = false
        bannerScrollView.layer.cornerRadius = 8
        bannerScrollView.delegate = self
        bannerScrollView.accessibilityIdentifier = "Offers"

        bannerStack.axis = .horizontal
        bannerStack.translatesAutoresizingMaskIntoConstraints = false
        bannerScrollView.addSubview(bannerStack)
        NSLayoutConstraint.activate([
            bannerStack.topAnchor.constraint(equalTo: bannerScrollView.topAnchor),
            bannerStack.bottomAnchor.constraint(equalTo: bannerScrollView.bottomAnchor),
            bannerStack.leadingAnchor.constraint(equalTo: bannerScrollView.leadingAnchor),
            bannerStack.trailingAnchor.constraint(equalTo: bannerScrollView.trailingAnchor),
            bannerStack.heightAnchor.constraint(equalTo: bannerScrollView.heightAnchor),
            bannerScrollView.heightAnchor.constraint(equalToConstant: 140)
        ])

        pageControl.currentPageIndicatorTintColor = ECStyle.brandBlue
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false

        let column = UIStackView(arrangedSubviews: [bannerScrollView, pageControl])
        column.axis = .vertical
        column.spacing = 4
        return column
    }

    // MARK: - Carousel

    private func startBannerTimer() {
        bannerTimer?.invalidate()
        bannerTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.showNextBanner()
        }
    }

    private func showNextBanner() {
        guard offers.count > 1, bannerScrollView.bounds.width > 0 else {
            return
        }
        let next = (pageControl.currentPage + 1) % offers.count
        bannerScrollView.setContentOffset(CGPoint(x: CGFloat(next) * bannerScrollView.bounds.width, y: 0), animated: true)
    }

    private func updateCurrentPage() {
        guard bannerScrollView.bounds.width > 0 else {
            return
        }
        pageControl.currentPage = Int((bannerScrollView.contentOffset.x / bannerScrollView.bounds.width).rounded())
    }

    // MARK: - Navigation

    @objc
    private func didTapSearch() {
        flow?.showSearch()
    }

    @objc
    private func didTapCategory(_ sender: UIControl) {
        openCategory(at: sender.tag)
    }

    @objc
    private func didTapOffer(_ sender: UIControl) {
        guard offers.indices.contains(sender.tag) else {
            return
        }
        flow?.showListing(for: .category(ECCatalog.category(withID: offers[sender.tag].category)))
    }

    @objc
    private func didTapDeal(_ sender: UIControl) {
        guard deals.indices.contains(sender.tag) else {
            return
        }
        flow?.showProduct(deals[sender.tag])
    }

    @objc
    private func didTapWishlist() {
        flow?.showWishlist()
    }

    @objc
    private func didTapCart() {
        guard !store.isEmpty else {
            return
        }
        flow?.showCart()
    }

    private func openCategory(at index: Int) {
        guard categories.indices.contains(index) else {
            return
        }
        flow?.showListing(for: .category(categories[index]))
    }
}

extension ECHomeViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
        // A swipe restarts the countdown, so the carousel does not jump right after the shopper moved it.
        startBannerTimer()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
}

// MARK: - Search

/// The search screen: trending searches before the shopper types, autocomplete while they do.
final class ECSearchViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var suggestions: [String] = []
    private var pendingSuggestions: DispatchWorkItem?
    private var visit = 0

    private var query: String {
        (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Trending searches while the box is empty, suggestions for what is typed otherwise.
    private var rows: [String] {
        query.isEmpty ? ECCatalog.trendingSearches : suggestions
    }

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

        title = "Search"
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Search"

        searchBar.placeholder = "Search for products, brands and more"
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .search
        searchBar.autocapitalizationType = .none
        searchBar.delegate = self
        searchBar.accessibilityIdentifier = "Search Box"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.accessibilityIdentifier = "Search Suggestions"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "suggestion")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        guard visit == 1 else {
            return
        }
        searchBar.becomeFirstResponder()

        // Types the query a keystroke at a time, so autocomplete requests and the replay both see a
        // shopper typing rather than a query appearing whole.
        ECAutoPilot.step(after: 1) { [weak self] in
            ECAutoPilot.type(
                "headphones",
                update: { text in
                    self?.searchBar.text = text
                    self?.queryDidChange()
                },
                completion: {
                    ECAutoPilot.step(after: 1.5) {
                        guard let self = self else {
                            return
                        }
                        self.submit(self.query)
                    }
                }
            )
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pendingSuggestions?.cancel()
    }

    // MARK: - Search

    /// Asks for suggestions once typing pauses, rather than on every keystroke.
    private func queryDidChange() {
        pendingSuggestions?.cancel()
        let typed = query
        guard !typed.isEmpty else {
            suggestions = []
            tableView.reloadData()
            return
        }

        let request = DispatchWorkItem { [weak self] in
            self?.api.loadSuggestions(query: typed) { suggestions in
                // A reply for text the shopper has since changed is stale.
                guard let self = self, self.query == typed else {
                    return
                }
                self.suggestions = suggestions
                self.tableView.reloadData()
            }
        }
        pendingSuggestions = request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: request)
    }

    private func submit(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        pendingSuggestions?.cancel()
        searchBar.text = trimmed
        searchBar.resignFirstResponder()
        flow?.showListing(for: .search(trimmed))
    }
}

extension ECSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        queryDidChange()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        submit(query)
    }
}

extension ECSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        query.isEmpty ? "Trending" : (suggestions.isEmpty ? nil : "Suggestions")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestion", for: indexPath)
        cell.textLabel?.text = rows[indexPath.row]
        cell.imageView?.image = UIImage(systemName: query.isEmpty ? "flame" : "magnifyingglass")
        cell.imageView?.tintColor = query.isEmpty ? ECStyle.buyNowOrange : .secondaryLabel
        cell.accessibilityIdentifier = "suggestion-\(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        submit(rows[indexPath.row])
    }
}

// MARK: - Listing

/// Products for a search or a category, with a sort bar. Rows lead to the product page.
final class ECProductListViewController: UIViewController, ECStoreScreen {
    /// What the listing shows.
    enum Source {
        case search(String)
        case category(ECCategory)
    }

    private let store: ECStore
    private let api: ECStoreAPI
    private let source: Source
    private var sort: ECSortOrder = .relevance
    private var products: [ECProduct] = []
    private let sortControl = UISegmentedControl(items: ECSortOrder.allCases.map(\.title))
    private let tableView = UITableView(frame: .zero, style: .plain)
    private lazy var cartButton = cartBarButton(store: store, action: #selector(didTapCart))

    private var isLoading = false
    /// Held until the listing request in flight returns, for steps that need the products on screen.
    private var onLoad: (() -> Void)?
    private var visit = 0

    init(store: ECStore, api: ECStoreAPI, source: Source) {
        self.store = store
        self.api = api
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch source {
        case .search(let query):
            title = "\u{201C}\(query)\u{201D}"
        case .category(let category):
            title = category.name
        }
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = cartButton
        view.backgroundColor = .systemBackground

        sortControl.selectedSegmentIndex = 0
        sortControl.accessibilityIdentifier = "Sort"
        sortControl.addTarget(self, action: #selector(didChangeSort), for: .valueChanged)
        sortControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sortControl)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.accessibilityIdentifier = "Product List"
        tableView.register(ECProductCell.self, forCellReuseIdentifier: ECProductCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            sortControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            sortControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: ECStyle.spacing),
            sortControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -ECStyle.spacing),
            tableView.topAnchor.constraint(equalTo: sortControl.bottomAnchor, constant: 8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        cartButton.title = cartTitle(store: store)
        guard visit == 1 else {
            return
        }

        // Loaded once the view has appeared, not in `viewDidLoad`: RUM starts this view on appearance,
        // and a request sent before that would be counted against the screen the shopper came from.
        load()

        switch source {
        case .search:
            // Re-sorts the results — a second search request, and a control the replay shows changing —
            // then opens the cheapest match.
            ECAutoPilot.step(after: 2) { [weak self] in
                self?.whenLoaded {
                    self?.applySort(.priceLowToHigh)
                    ECAutoPilot.step(after: 2) { self?.whenLoaded { self?.openFirstProductNotInCart() } }
                }
            }
        case .category:
            ECAutoPilot.step(after: 1.5) { [weak self] in
                self?.whenLoaded {
                    self?.scrollToEnd()
                    ECAutoPilot.step(after: 1.5) { self?.openFirstProductNotInCart() }
                }
            }
        }
    }

    // MARK: - Loading

    private func load() {
        isLoading = true
        let completion: ([ECProduct]) -> Void = { [weak self] products in
            guard let self = self else {
                return
            }
            self.isLoading = false
            self.products = products
            self.tableView.reloadData()
            self.showEmptyStateIfNeeded()

            let pending = self.onLoad
            self.onLoad = nil
            pending?()
        }

        switch source {
        case .search(let query):
            api.search(query: query, sort: sort, completion: completion)
        case .category(let category):
            api.loadProducts(category: category.id, sort: sort, completion: completion)
        }
    }

    /// Runs `action` now if the products are on screen, or as soon as the request in flight returns.
    private func whenLoaded(_ action: @escaping () -> Void) {
        if isLoading {
            onLoad = action
        } else {
            action()
        }
    }

    private func showEmptyStateIfNeeded() {
        guard products.isEmpty else {
            tableView.backgroundView = nil
            return
        }
        let message = ECStyle.label("No products found.\nTry a different search or category.", style: .body, color: .secondaryLabel)
        message.textAlignment = .center
        tableView.backgroundView = message
    }

    // MARK: - Sorting

    @objc
    private func didChangeSort() {
        let order = ECSortOrder.allCases[sortControl.selectedSegmentIndex]
        guard order != sort else {
            return
        }
        sort = order
        load()
    }

    private func applySort(_ order: ECSortOrder) {
        guard let index = ECSortOrder.allCases.firstIndex(of: order) else {
            return
        }
        sortControl.selectedSegmentIndex = index
        didChangeSort()
    }

    // MARK: - Navigation

    private func scrollToEnd() {
        guard !products.isEmpty else {
            return
        }
        tableView.scrollToRow(at: IndexPath(row: products.count - 1, section: 0), at: .bottom, animated: true)
    }

    /// Opens the first product the shopper has not already put in the cart, so each pass through the
    /// funnel adds something new.
    private func openFirstProductNotInCart() {
        let index = products.firstIndex { !store.contains($0) } ?? 0
        select(at: index)
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
}

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

/// A listing row: photo, title, rating, price with MRP and discount.
private final class ECProductCell: UITableViewCell {
    static let reuseIdentifier = "ECProductCell"

    private let imageSlot = UIStackView()
    private let details = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        details.axis = .vertical
        details.spacing = 6

        imageSlot.alignment = .top

        let row = UIStackView(arrangedSubviews: [imageSlot, details])
        row.axis = .horizontal
        row.spacing = ECStyle.spacing
        row.alignment = .top
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
        ECStyle.replaceArrangedSubviews(of: imageSlot, with: [ECStyle.productImage(for: product, side: 88)])

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
        lines.append(ECStyle.label(product.price >= 500 ? "Free delivery" : "Delivery ₹40", style: .caption1, color: .secondaryLabel))
        ECStyle.replaceArrangedSubviews(of: details, with: lines)

        accessibilityIdentifier = "product-\(product.id)"
    }
}
