/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

/// A top-level department, like Electronics or Grocery.
struct ProductCategory: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let symbolName: String
    /// `#RRGGBB` the category's icon is tinted with.
    let tintHex: String
}

/// A banner in the home screen's promotional carousel.
struct PromoBanner: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let ctaTitle: String
    let imageURL: URL?
    /// `#RRGGBB` behind the banner's text.
    let backgroundHex: String
    let targetType: String
    let targetValue: String

    /// Where tapping the banner leads.
    var target: BannerTarget {
        switch targetType {
        case "flashSale": return .flashSale
        case "category": return .category(id: targetValue)
        case "product": return .product(id: targetValue)
        case "search": return .search(query: targetValue)
        default: return .none
        }
    }
}

enum BannerTarget: Hashable, Sendable {
    case flashSale
    case category(id: String)
    case product(id: String)
    case search(query: String)
    case none
}

/// The whole catalog in one response: what the product service's `fetchCatalog()` returns.
struct CatalogPayload: Codable, Sendable {
    let generatedAt: Date?
    let currency: String
    let categories: [ProductCategory]
    let banners: [PromoBanner]
    let products: [Product]
}

extension JSONDecoder {
    /// The decoder every service response goes through: ISO-8601 dates.
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
