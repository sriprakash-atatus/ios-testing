/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

enum ProductSort: String, CaseIterable, Identifiable, Codable, Sendable {
    case relevance
    case popularity
    case priceLowToHigh
    case priceHighToLow
    case rating
    case discount
    case newest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .relevance: return "Relevance"
        case .popularity: return "Popularity"
        case .priceLowToHigh: return "Price — Low to High"
        case .priceHighToLow: return "Price — High to Low"
        case .rating: return "Customer Rating"
        case .discount: return "Discount"
        case .newest: return "Newest First"
        }
    }

    var symbolName: String {
        switch self {
        case .relevance: return "sparkle.magnifyingglass"
        case .popularity: return "flame"
        case .priceLowToHigh: return "arrow.up"
        case .priceHighToLow: return "arrow.down"
        case .rating: return "star"
        case .discount: return "tag"
        case .newest: return "clock"
        }
    }

    /// Orders `products`. `.relevance` keeps the order they came in, which is the ranking for search
    /// results and the catalog's own order otherwise.
    func apply(to products: [Product]) -> [Product] {
        switch self {
        case .relevance:
            return products
        case .popularity:
            return products.sorted { $0.reviewCount > $1.reviewCount }
        case .priceLowToHigh:
            return products.sorted { $0.price < $1.price }
        case .priceHighToLow:
            return products.sorted { $0.price > $1.price }
        case .rating:
            return products.sorted { ($0.rating, $0.reviewCount) > ($1.rating, $1.reviewCount) }
        case .discount:
            return products.sorted { $0.discount > $1.discount }
        case .newest:
            return products.sorted { ($0.isNewArrival ? 1 : 0, $0.rating) > ($1.isNewArrival ? 1 : 0, $1.rating) }
        }
    }
}

struct ProductFilter: Hashable, Codable, Sendable {
    var categories: Set<String> = []
    var brands: Set<String> = []
    var minPrice: Double?
    var maxPrice: Double?
    /// Products rated at least this, e.g. `4` for "4★ & above".
    var minimumRating: Double?
    /// Products discounted at least this percentage.
    var minimumDiscount: Int?
    var inStockOnly = false

    static let ratingOptions: [Double] = [4, 3, 2]
    static let discountOptions: [Int] = [10, 25, 40, 60]

    init(
        categories: Set<String> = [],
        brands: Set<String> = [],
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        minimumRating: Double? = nil,
        minimumDiscount: Int? = nil,
        inStockOnly: Bool = false
    ) {
        self.categories = categories
        self.brands = brands
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.minimumRating = minimumRating
        self.minimumDiscount = minimumDiscount
        self.inStockOnly = inStockOnly
    }

    var hasPriceRange: Bool { minPrice != nil || maxPrice != nil }

    /// How many kinds of filter are set, for the badge on the filter button.
    var activeCount: Int {
        [
            !categories.isEmpty,
            !brands.isEmpty,
            hasPriceRange,
            minimumRating != nil,
            minimumDiscount != nil,
            inStockOnly
        ].filter { $0 }.count
    }

    var isEmpty: Bool { activeCount == 0 }

    func matches(_ product: Product) -> Bool {
        if !categories.isEmpty && !categories.contains(product.category) {
            return false
        }
        if !brands.isEmpty && !brands.contains(product.brand) {
            return false
        }
        if let minPrice = minPrice, product.price < minPrice {
            return false
        }
        if let maxPrice = maxPrice, product.price > maxPrice {
            return false
        }
        if let minimumRating = minimumRating, product.rating < minimumRating {
            return false
        }
        if let minimumDiscount = minimumDiscount, product.discount < minimumDiscount {
            return false
        }
        if inStockOnly && !product.isInStock {
            return false
        }
        return true
    }

    func apply(to products: [Product]) -> [Product] {
        products.filter(matches)
    }

    mutating func reset() {
        self = ProductFilter()
    }
}

/// The product rails on the home screen.
enum HomeSection: String, CaseIterable, Identifiable, Codable, Sendable {
    case flashSale
    case popular
    case trending
    case bestSellers
    case newArrivals
    case recommended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flashSale: return "Flash Sale"
        case .popular: return "Popular Products"
        case .trending: return "Trending Now"
        case .bestSellers: return "Best Sellers"
        case .newArrivals: return "New Arrivals"
        case .recommended: return "Recommended for You"
        }
    }

    var subtitle: String {
        switch self {
        case .flashSale: return "Deep discounts, for a limited time"
        case .popular: return "Most loved by shoppers"
        case .trending: return "What everyone is buying this week"
        case .bestSellers: return "Top sellers across categories"
        case .newArrivals: return "Just landed in store"
        case .recommended: return "Picked based on your activity"
        }
    }

    var symbolName: String {
        switch self {
        case .flashSale: return "bolt.fill"
        case .popular: return "heart.fill"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .bestSellers: return "trophy.fill"
        case .newArrivals: return "sparkles"
        case .recommended: return "hand.thumbsup.fill"
        }
    }
}

/// What a product listing shows, and how it opens.
struct ProductListContext: Hashable, Codable, Sendable {
    enum Source: Hashable, Codable, Sendable {
        case all
        case category(id: String)
        case section(HomeSection)
        case search(query: String)
        case brand(name: String)
    }

    var title: String
    var source: Source
    var initialFilter: ProductFilter
    var initialSort: ProductSort

    init(title: String, source: Source, initialFilter: ProductFilter = ProductFilter(), initialSort: ProductSort = .relevance) {
        self.title = title
        self.source = source
        self.initialFilter = initialFilter
        self.initialSort = initialSort
    }

    static let allProducts = ProductListContext(title: "All Products", source: .all)

    static func category(_ category: ProductCategory) -> ProductListContext {
        ProductListContext(title: category.name, source: .category(id: category.id))
    }

    static func section(_ section: HomeSection) -> ProductListContext {
        ProductListContext(
            title: section.title,
            source: .section(section),
            initialSort: section == .flashSale ? .discount : .relevance
        )
    }

    static func search(_ query: String) -> ProductListContext {
        ProductListContext(title: "“\(query)”", source: .search(query: query))
    }

    static func brand(_ name: String) -> ProductListContext {
        ProductListContext(title: name, source: .brand(name: name))
    }
}

enum ListingLayout: String, CaseIterable, Identifiable, Codable, Sendable {
    case grid
    case list

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }

    /// The other layout, for the toggle button.
    var toggled: ListingLayout { self == .grid ? .list : .grid }
}

struct SearchSuggestion: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case product(id: String)
        case category(id: String)
        case brand(name: String)
        case query
    }

    let text: String
    let detail: String?
    let kind: Kind

    var id: String { "\(kind)-\(text)" }

    var symbolName: String {
        switch kind {
        case .product: return "bag"
        case .category: return "square.grid.2x2"
        case .brand: return "tag"
        case .query: return "magnifyingglass"
        }
    }
}

/// The progress of a load, for views that show skeletons, content or an error.
enum LoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(message: String)

    var isLoading: Bool { self == .loading }

    var errorMessage: String? {
        if case .failed(let message) = self {
            return message
        }
        return nil
    }
}
