/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: The store's backend calls. Real `URLSession` requests through an instrumented session, so
// the agent captures them itself as RUM resources and network spans — the store never reports a
// resource or a span by hand.

import Foundation
import AtatusCore

final class ECStoreAPI {
    /// The store's backend. A public catalogue API, so the funnel makes the requests a shop actually
    /// makes rather than pretend ones. Overridable with `AT_TEST_STORE_API_URL` for a run that has to
    /// stay inside its own network.
    static let baseURL = Environment.storeAPIURL()

    /// The host RUM and Trace treat as first party, which is what turns these requests into traced
    /// resources with propagated headers.
    static var host: String { baseURL.host ?? "" }

    private let session: URLSession

    init() {
        // Registers the delegate class with the agent. Combined with `firstPartyHostsTracing` in the
        // RUM and Trace configuration, this is the whole of the store's network instrumentation.
        URLSessionInstrumentation.enableDurationBreakdown(
            with: .init(delegateClass: CustomURLSessionDelegate.self)
        )
        session = URLSession(
            configuration: .ephemeral,
            delegate: CustomURLSessionDelegate(),
            delegateQueue: nil
        )
    }

    // MARK: - Catalog

    /// Loads the catalog, falling back to the bundled products when the request fails so an offline
    /// runner still has screens to walk through.
    func loadCatalog(completion: @escaping ([ECProduct]) -> Void) {
        get("/products?limit=5") { data in
            guard let data = data,
                  let products = try? JSONDecoder().decode([ECProduct].self, from: data),
                  !products.isEmpty else {
                completion(ECCatalog.fallback)
                return
            }
            completion(products)
        }
    }

    func loadProduct(id: Int, completion: @escaping (ECProduct?) -> Void) {
        get("/products/\(id)") { data in
            completion(data.flatMap { try? JSONDecoder().decode(ECProduct.self, from: $0) })
        }
    }

    // MARK: - Cart and orders

    func addToCart(productID: Int, quantity: Int, completion: @escaping () -> Void) {
        post("/carts", body: ["userId": 1, "products": [["productId": productID, "quantity": quantity]]]) { _ in
            completion()
        }
    }

    /// Authorises the payment. Sent to a path the API does not serve, so the first attempt comes back
    /// a failure — a real failed request, captured as an errored resource and span without the store
    /// reporting an error itself.
    func authorizePayment(amount: Double, succeeds: Bool, completion: @escaping (Bool) -> Void) {
        let path = succeeds ? "/carts" : "/payments/authorize"
        post(path, body: ["amount": amount, "currency": "USD"]) { succeeded in
            completion(succeeded)
        }
    }

    func placeOrder(lines: [ECCartLine], completion: @escaping (String?) -> Void) {
        let products = lines.map { ["productId": $0.product.id, "quantity": $0.quantity] }
        post("/carts", body: ["userId": 1, "products": products]) { succeeded in
            completion(succeeded ? "ORD-\(Int.random(in: 100_000...999_999))" : nil)
        }
    }

    // MARK: - Transport

    private func get(_ path: String, completion: @escaping (Data?) -> Void) {
        send(URLRequest(url: url(path))) { data, _ in completion(data) }
    }

    private func post(_ path: String, body: [String: Any], completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        send(request) { _, succeeded in completion(succeeded) }
    }

    private func send(_ request: URLRequest, completion: @escaping (Data?, Bool) -> Void) {
        session.dataTask(with: request) { data, response, _ in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let succeeded = (200..<400).contains(statusCode)
            // Back to the main queue: every caller updates the UI with the result.
            DispatchQueue.main.async {
                completion(succeeded ? data : nil, succeeded)
            }
        }
        .resume()
    }

    private func url(_ path: String) -> URL {
        URL(string: Self.baseURL.absoluteString + path) ?? Self.baseURL
    }
}
