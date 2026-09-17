/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

/// A product as the catalog API returns it.
struct Product: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let description: String
    /// The `ProductCategory.id` the product is listed under.
    let category: String
    let subcategory: String
    let brand: String
    let price: Double
    let originalPrice: Double
    /// Whole-percent discount off `originalPrice`.
    let discount: Int
    let rating: Double
    let reviewCount: Int
    let images: [URL]
    let thumbnail: URL?
    let colors: [ProductColor]
    let sizes: [String]
    /// What `sizes` measures — "Size", "Storage", "Volume" — or empty when the product has none.
    let sizeLabel: String
    let stock: Int
    let seller: Seller
    let specifications: [Specification]
    let highlights: [String]
    let reviews: [Review]
    let tags: [String]
    let isFlashSale: Bool
    let isNewArrival: Bool
    let soldCount: Int
    let warranty: String
    let returnPolicy: String
    /// SF Symbol drawn in place of the product photo when it cannot be loaded.
    let symbolName: String
}

extension Product {
    /// The most one order may hold of this product.
    static let maximumOrderQuantity = 10

    var isInStock: Bool { stock > 0 }
    var isLowStock: Bool { stock > 0 && stock <= 10 }

    var availability: ProductAvailability {
        if stock <= 0 {
            return .outOfStock
        }
        return stock <= 10 ? .lowStock(remaining: stock) : .inStock
    }

    var hasDiscount: Bool { discount > 0 && originalPrice > price }
    var savings: Double { max(originalPrice - price, 0) }

    /// The image product pages lead with.
    var primaryImageURL: URL? { images.first ?? thumbnail }
    /// The smaller image cards and rows use.
    var thumbnailURL: URL? { thumbnail ?? images.first }

    /// How many a shopper may put in the cart: the stock, capped at the per-order limit.
    var purchasableQuantity: Int { max(0, min(stock, Self.maximumOrderQuantity)) }

    /// The description's first sentence, for cards.
    var shortDescription: String {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let end = trimmed.firstIndex(where: { $0 == "." || $0 == "!" || $0 == "?" }) else {
            return trimmed
        }
        return String(trimmed[...end])
    }

    /// An estimate of how the product's ratings spread across one to five stars, derived from the
    /// average and the total so the review summary has bars to draw.
    var ratingBreakdown: [RatingBucket] {
        let weights = (1...5).map { star in exp(-abs(Double(star) - rating) * 1.7) }
        let total = weights.reduce(0, +)
        return (1...5).reversed().map { star in
            let share = weights[star - 1] / total
            return RatingBucket(stars: star, count: Int((share * Double(reviewCount)).rounded()), share: share)
        }
    }
}

enum ProductAvailability: Hashable, Sendable {
    case inStock
    case lowStock(remaining: Int)
    case outOfStock

    var title: String {
        switch self {
        case .inStock: return "In stock"
        case .lowStock(let remaining): return "Only \(remaining) left"
        case .outOfStock: return "Out of stock"
        }
    }
}

struct RatingBucket: Identifiable, Hashable, Sendable {
    let stars: Int
    let count: Int
    /// Fraction of all ratings, from 0 to 1.
    let share: Double

    var id: Int { stars }
}

struct ProductColor: Identifiable, Hashable, Codable, Sendable {
    let name: String
    /// `#RRGGBB`.
    let hex: String

    var id: String { name }
}

struct Seller: Hashable, Codable, Sendable {
    let name: String
    let rating: Double
    let yearsActive: Int
    let isVerified: Bool
    let location: String
}

struct Specification: Identifiable, Hashable, Codable, Sendable {
    let title: String
    let value: String

    var id: String { title }
}

struct Review: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let author: String
    /// One to five.
    let rating: Int
    let title: String
    let comment: String
    let date: Date
    let isVerifiedPurchase: Bool
    let helpfulCount: Int
}
