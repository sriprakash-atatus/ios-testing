/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: The store's backend calls. Real `URLSession` requests through an instrumented session, so
// the agent captures them itself as RUM resources and network spans — the store never reports a
// resource or a span by hand.

import Foundation
// `URLSessionInstrumentation` is re-exported by AtatusRUM (and AtatusTrace), not by AtatusCore.
import AtatusRUM

final class ECStoreAPI {
    /// The store's backend — the local Node server (`local server/server.js`), which serves
    /// `/api/store/*` and runs the Atatus Node APM agent. Each call the app makes is therefore
    /// recorded twice: by the iOS agent as a RUM resource and client span, and by the Node agent as
    /// a server-side transaction, joined by the `traceparent` the iOS agent propagates.
    ///
    /// Defaults to the intake the agent already reports to, since that is the same server.
    /// `AT_TEST_STORE_API_URL` overrides it.
    static let baseURL = Environment.storeAPIURL()

    /// The host RUM and Trace treat as first party, which is what turns these requests into traced
    /// resources with propagated headers.
    static var host: String { baseURL.host ?? "" }

    private let session: URLSession

    init() {
        // Registers the delegate class with the agent. Combined with `firstPartyHostsTracing` in the
        // RUM and Trace configuration, this is the whole of the store's network instrumentation.
        URLSessionInstrumentation.enable(
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
        get("/api/store/products?limit=5") { data in
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
        get("/api/store/products/\(id)") { data in
            completion(data.flatMap { try? JSONDecoder().decode(ECProduct.self, from: $0) })
        }
    }

    // MARK: - Cart and orders

    func addToCart(productID: Int, quantity: Int, completion: @escaping () -> Void) {
        post("/api/store/cart/items", body: ["productId": productID, "quantity": quantity]) { _, _ in
            completion()
        }
    }

    /// Authorises the payment. The server declines attempt 1 with a 502 and accepts the retry, so the
    /// run captures a genuinely failed request — an errored resource and span on the app side, an
    /// errored transaction on the backend — without the store reporting an error itself.
    func authorizePayment(amount: Double, attempt: Int, completion: @escaping (Bool) -> Void) {
        post("/api/store/payments/authorize", body: ["amount": amount, "currency": "USD", "attempt": attempt]) { _, succeeded in
            completion(succeeded)
        }
    }

    /// Creates the order and returns the reference the backend assigned it.
    func placeOrder(lines: [ECCartLine], completion: @escaping (String?) -> Void) {
        let products = lines.map { ["productId": $0.product.id, "quantity": $0.quantity] }
        post("/api/store/orders", body: ["products": products]) { data, succeeded in
            guard succeeded,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let reference = json["reference"] as? String else {
                completion(nil)
                return
            }
            completion(reference)
        }
    }

    // MARK: - Transport

    private func get(_ path: String, completion: @escaping (Data?) -> Void) {
        send(URLRequest(url: url(path))) { data, _ in completion(data) }
    }

    private func post(_ path: String, body: [String: Any], completion: @escaping (Data?, Bool) -> Void) {
        var request = URLRequest(url: url(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        send(request, completion: completion)
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
