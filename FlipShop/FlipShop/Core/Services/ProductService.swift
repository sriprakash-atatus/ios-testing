/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

protocol ProductServiceProtocol: Sendable {
    /// Categories, banners and every product, in one response.
    func fetchCatalog() async throws -> CatalogPayload
    func fetchProduct(id: String) async throws -> Product
}

/// Serves the catalog bundled with the app (`catalog.json`) as if it came over the network.
final class MockProductService: ProductServiceProtocol, @unchecked Sendable {
    private let bundle: Bundle
    private let resourceName: String
    private let lock = NSLock()
    private var cachedPayload: CatalogPayload?

    init(bundle: Bundle = .main, resourceName: String = "catalog") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func fetchCatalog() async throws -> CatalogPayload {
        try await MockNetwork.delay()
        return try payload()
    }

    func fetchProduct(id: String) async throws -> Product {
        try await MockNetwork.delay(0.2...0.5)
        guard let product = try payload().products.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return product
    }

    private func payload() throws -> CatalogPayload {
        lock.lock()
        defer { lock.unlock() }
        if let cachedPayload = cachedPayload {
            return cachedPayload
        }
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw APIError.notFound
        }
        do {
            let decoded = try JSONDecoder.api.decode(CatalogPayload.self, from: Data(contentsOf: url))
            cachedPayload = decoded
            return decoded
        } catch {
            throw APIError.decoding
        }
    }
}

/// The same service against a REST backend: `GET /catalog`, `GET /products/{id}`.
struct RemoteProductService: ProductServiceProtocol {
    let client: APIClient

    func fetchCatalog() async throws -> CatalogPayload {
        try await client.send(Endpoint(path: "catalog"), as: CatalogPayload.self)
    }

    func fetchProduct(id: String) async throws -> Product {
        try await client.send(Endpoint(path: "products/\(id)"), as: Product.self)
    }
}
