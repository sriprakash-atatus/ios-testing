/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

protocol SearchServiceProtocol: Sendable {
    func popularSearches() async throws -> [String]
    /// Products matching `query`, best match first.
    func search(_ query: String, in products: [Product]) async throws -> [Product]
}

struct MockSearchService: SearchServiceProtocol {
    func popularSearches() async throws -> [String] {
        try await MockNetwork.delay(0.1...0.3)
        return ["iPhone", "Running shoes", "Smart watch", "Sunglasses", "Perfume", "Laptop", "Sofa", "Handbag", "Lipstick", "Dumbbells"]
    }

    func search(_ query: String, in products: [Product]) async throws -> [Product] {
        try await MockNetwork.delay(0.25...0.6)
        return SearchEngine.rank(products, for: query)
    }
}

/// Matching and ranking, shared by search results and as-you-type suggestions.
enum SearchEngine {
    /// Products where every word of `query` appears in the name, brand, category or tags, ordered so
    /// name matches beat brand matches beat description matches.
    static func rank(_ products: [Product], for query: String) -> [Product] {
        let terms = tokens(query)
        guard !terms.isEmpty else {
            return []
        }
        return products
            .compactMap { product -> (Product, Int)? in
                let score = self.score(product, terms: terms)
                return score > 0 ? (product, score) : nil
            }
            .sorted { lhs, rhs in
                lhs.1 != rhs.1 ? lhs.1 > rhs.1 : lhs.0.reviewCount > rhs.0.reviewCount
            }
            .map(\.0)
    }

    /// Up to `limit` suggestions for what has been typed: matching categories and brands first, then products.
    static func suggestions(for query: String, products: [Product], categories: [ProductCategory], limit: Int = 8) -> [SearchSuggestion] {
        let terms = tokens(query)
        guard let first = terms.first else {
            return []
        }
        let lowered = query.lowercased().trimmingCharacters(in: .whitespaces)

        let categoryMatches = categories
            .filter { $0.name.lowercased().contains(lowered) || $0.id.contains(first) }
            .map { SearchSuggestion(text: $0.name, detail: "Category", kind: .category(id: $0.id)) }

        var seenBrands = Set<String>()
        let brandMatches = products
            .filter { $0.brand.lowercased().hasPrefix(first) }
            .compactMap { product -> SearchSuggestion? in
                guard seenBrands.insert(product.brand).inserted else {
                    return nil
                }
                return SearchSuggestion(text: product.brand, detail: "Brand", kind: .brand(name: product.brand))
            }

        let productMatches = rank(products, for: query)
            .prefix(limit)
            .map { SearchSuggestion(text: $0.name, detail: $0.subcategory, kind: .product(id: $0.id)) }

        var combined: [SearchSuggestion] = []
        combined.append(contentsOf: categoryMatches.prefix(2))
        combined.append(contentsOf: brandMatches.prefix(2))
        combined.append(contentsOf: productMatches)
        return Array(combined.prefix(limit))
    }

    static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private static func score(_ product: Product, terms: [String]) -> Int {
        let name = product.name.lowercased()
        let brand = product.brand.lowercased()
        let category = "\(product.category) \(product.subcategory)".lowercased()
        let tags = product.tags.joined(separator: " ").lowercased()
        let description = product.description.lowercased()

        var total = 0
        for term in terms {
            var best = 0
            if name.hasPrefix(term) {
                best = 100
            } else if name.contains(term) {
                best = 70
            } else if brand.contains(term) {
                best = 50
            } else if category.contains(term) {
                best = 35
            } else if tags.contains(term) {
                best = 25
            } else if description.contains(term) {
                best = 8
            }
            guard best > 0 else {
                // Every term has to match somewhere.
                return 0
            }
            total += best
        }
        return total
    }
}
