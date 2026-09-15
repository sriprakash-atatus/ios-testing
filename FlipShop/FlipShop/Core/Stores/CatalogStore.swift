/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

/// Categories, banners and products, loaded once and shared by every screen that browses.
@MainActor
@Observable
final class CatalogStore {
    private(set) var products: [Product] = []
    private(set) var categories: [ProductCategory] = []
    private(set) var banners: [PromoBanner] = []
    private(set) var state: LoadState = .idle
    private(set) var lastUpdated: Date?
    /// The current flash sale runs until midnight.
    private(set) var flashSaleEndsAt: Date

    @ObservationIgnored private let service: any ProductServiceProtocol
    @ObservationIgnored private var productsByID: [String: Product] = [:]

    init(service: any ProductServiceProtocol) {
        self.service = service
        self.flashSaleEndsAt = CatalogStore.midnight(after: Date())
    }

    var hasContent: Bool { !products.isEmpty }

    // MARK: - Loading

    func loadIfNeeded() async {
        guard products.isEmpty, !state.isLoading else {
            return
        }
        await load()
    }

    func load() async {
        state = .loading
        do {
            apply(try await service.fetchCatalog())
            state = .loaded
        } catch {
            state = .failed(message: APIError.message(for: error))
        }
    }

    /// Reloads for pull-to-refresh. What is on screen stays if the reload fails; the error message is
    /// returned for a toast.
    @discardableResult
    func refresh() async -> String? {
        do {
            apply(try await service.fetchCatalog())
            state = .loaded
            return nil
        } catch {
            let message = APIError.message(for: error)
            if products.isEmpty {
                state = .failed(message: message)
            }
            return message
        }
    }

    /// Fetches one product's latest details, for a product page's pull-to-refresh.
    func latestProduct(id: String) async -> Product? {
        guard let product = try? await service.fetchProduct(id: id) else {
            return productsByID[id]
        }
        productsByID[id] = product
        if let index = products.firstIndex(where: { $0.id == id }) {
            products[index] = product
        }
        return product
    }

    /// Moves the flash sale on to the next day once it has ended.
    func rollFlashSaleIfEnded(now: Date = Date()) {
        if now >= flashSaleEndsAt {
            flashSaleEndsAt = CatalogStore.midnight(after: now)
        }
    }

    // MARK: - Lookup

    func product(id: String) -> Product? {
        productsByID[id]
    }

    func category(id: String) -> ProductCategory? {
        categories.first { $0.id == id }
    }

    func products(inCategory categoryID: String) -> [Product] {
        products.filter { $0.category == categoryID }
    }

    func productCount(inCategory categoryID: String) -> Int {
        products.reduce(0) { $1.category == categoryID ? $0 + 1 : $0 }
    }

    func products(for section: HomeSection, limit: Int? = nil) -> [Product] {
        let ranked: [Product]
        switch section {
        case .flashSale:
            ranked = products.filter { $0.isFlashSale && $0.isInStock }.sorted { $0.discount > $1.discount }
        case .popular:
            ranked = products.sorted { $0.reviewCount > $1.reviewCount }
        case .trending:
            ranked = products
                .filter { $0.rating >= 4 && $0.discount >= 15 }
                .sorted { Double($0.soldCount) * Double($0.discount) > Double($1.soldCount) * Double($1.discount) }
        case .bestSellers:
            ranked = products.sorted { $0.soldCount > $1.soldCount }
        case .newArrivals:
            ranked = products.filter(\.isNewArrival).sorted { $0.rating > $1.rating }
        case .recommended:
            ranked = products
                .filter { $0.rating >= 4.2 && $0.isInStock }
                .sorted { $0.rating * log(Double($0.reviewCount + 1)) > $1.rating * log(Double($1.reviewCount + 1)) }
        }
        return limit.map { Array(ranked.prefix($0)) } ?? ranked
    }

    func products(for source: ProductListContext.Source) -> [Product] {
        switch source {
        case .all:
            return products
        case .category(let id):
            return products(inCategory: id)
        case .section(let section):
            return products(for: section)
        case .search(let query):
            return SearchEngine.rank(products, for: query)
        case .brand(let name):
            return products.filter { $0.brand == name }
        }
    }

    /// Well-rated products from the categories of `productIDs` — what the shopper wishlisted, carted
    /// or viewed — falling back to general recommendations.
    func recommended(basedOn productIDs: [String], limit: Int = 10) -> [Product] {
        let seen = Set(productIDs)
        let interests = Set(productIDs.compactMap { productsByID[$0]?.category })
        guard !interests.isEmpty else {
            return products(for: .recommended, limit: limit)
        }
        let picks = products
            .filter { interests.contains($0.category) && !seen.contains($0.id) && $0.isInStock }
            .sorted { $0.rating > $1.rating }
        let fill = products(for: .recommended).filter { !seen.contains($0.id) && !interests.contains($0.category) }
        return Array((picks + fill).prefix(limit))
    }

    /// Products like `product`: its subcategory first, then its category.
    func related(to product: Product, limit: Int = 10) -> [Product] {
        let sameSubcategory = products.filter { $0.id != product.id && $0.subcategory == product.subcategory }
        let sameCategory = products.filter { $0.id != product.id && $0.category == product.category && $0.subcategory != product.subcategory }
        return Array((sameSubcategory.sorted { $0.rating > $1.rating } + sameCategory.sorted { $0.rating > $1.rating }).prefix(limit))
    }

    /// The brands among `products`, alphabetically.
    func brands(in products: [Product]) -> [String] {
        Array(Set(products.map(\.brand))).sorted()
    }

    /// The cheapest to dearest price among `products`, for the price filter.
    func priceRange(of products: [Product]) -> ClosedRange<Double> {
        guard let lowest = products.map(\.price).min(), let highest = products.map(\.price).max() else {
            return 0...1
        }
        return lowest...max(highest, lowest + 1)
    }

    // MARK: - Private

    private func apply(_ payload: CatalogPayload) {
        categories = payload.categories
        banners = payload.banners
        products = payload.products
        productsByID = Dictionary(payload.products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        lastUpdated = Date()
        rollFlashSaleIfEnded()
    }

    private static func midnight(after date: Date, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date.addingTimeInterval(24 * 60 * 60)
    }
}
