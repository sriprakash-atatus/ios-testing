/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: The store's backend calls. Real `URLSession` requests through an instrumented session, so
// the agent captures them itself as RUM resources and network spans — the store never reports a
// resource or a span by hand.
//
// Every read falls back to the bundled catalog when its request fails, so the funnel walks to the
// end against an offline or older backend too — the failed requests are then what gets captured.

import Foundation
// `URLSessionInstrumentation` is re-exported by AtatusRUM (and AtatusTrace), not by AtatusCore.
import AtatusRUM
import AtatusLogs

/// What the backend answers when it creates an order.
struct ECOrderReceipt: Decodable {
    let reference: String
    let deliveryDays: Int?
}

final class ECStoreAPI {
    private lazy var logger: LoggerProtocol = Logger.create()
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

    // MARK: - Home

    func loadCategories(completion: @escaping ([ECCategory]) -> Void) {
        get("/api/store/categories") { data in
            completion(Self.decode([ECCategory].self, from: data) ?? ECCatalog.categories)
        }
    }

    func loadOffers(completion: @escaping ([ECOffer]) -> Void) {
        get("/api/store/offers") { data in
            completion(Self.decode([ECOffer].self, from: data) ?? ECCatalog.offers)
        }
    }

    /// The home screen's "Deals of the Day": the catalog's biggest discounts.
    func loadDeals(completion: @escaping ([ECProduct]) -> Void) {
        let query = [URLQueryItem(name: "limit", value: "6"), URLQueryItem(name: "sort", value: ECSortOrder.discount.rawValue)]
        get("/api/store/products", query: query) { data in
            completion(Self.decode([ECProduct].self, from: data) ?? ECSortOrder.discount.sorted(ECCatalog.fallback))
        }
    }

    // MARK: - Catalog

    func loadProducts(category: String, sort: ECSortOrder, completion: @escaping ([ECProduct]) -> Void) {
        let query = [URLQueryItem(name: "category", value: category), URLQueryItem(name: "sort", value: sort.rawValue)]
        get("/api/store/products", query: query) { data in
            completion(Self.decode([ECProduct].self, from: data) ?? sort.sorted(ECCatalog.products(in: category)))
        }
    }

    func loadProduct(id: Int, completion: @escaping (ECProduct?) -> Void) {
        get("/api/store/products/\(id)") { data in
            completion(Self.decode(ECProduct.self, from: data))
        }
    }

    // MARK: - Search

    func search(query: String, sort: ECSortOrder, completion: @escaping ([ECProduct]) -> Void) {
        let items = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "sort", value: sort.rawValue)]
        get("/api/store/search", query: items) { data in
            completion(Self.decode([ECProduct].self, from: data) ?? sort.sorted(ECCatalog.search(query)))
        }
    }

    /// Autocomplete for the search box.
    func loadSuggestions(query: String, completion: @escaping ([String]) -> Void) {
        get("/api/store/search/suggestions", query: [URLQueryItem(name: "q", value: query)]) { data in
            let fallback = ECCatalog.search(query).prefix(5).map { $0.title.lowercased() }
            completion(Self.decode([String].self, from: data) ?? fallback)
        }
    }

    // MARK: - Delivery

    /// Checks whether `productID` ships to `pincode`. The backend answers 400 for a malformed pincode,
    /// which reaches the completion as `nil`.
    func checkDelivery(pincode: String, productID: Int, completion: @escaping (ECDeliveryEstimate?) -> Void) {
        let query = [URLQueryItem(name: "pincode", value: pincode), URLQueryItem(name: "productId", value: "\(productID)")]
        get("/api/store/delivery", query: query) { data in
            completion(Self.decode(ECDeliveryEstimate.self, from: data))
        }
    }

    // MARK: - Cart and wishlist

    func addToCart(productID: Int, quantity: Int, completion: @escaping () -> Void) {
        send("POST", "/api/store/cart/items", body: ["productId": productID, "quantity": quantity]) { _, _ in
            completion()
        }
    }

    func updateCartItem(productID: Int, quantity: Int, completion: @escaping () -> Void) {
        send("PUT", "/api/store/cart/items/\(productID)", body: ["quantity": quantity]) { _, _ in
            completion()
        }
    }

    func removeFromCart(productID: Int, completion: @escaping () -> Void) {
        send("DELETE", "/api/store/cart/items/\(productID)") { _, _ in
            completion()
        }
    }

    func addToWishlist(productID: Int, completion: @escaping () -> Void) {
        send("POST", "/api/store/wishlist/items", body: ["productId": productID]) { _, _ in
            completion()
        }
    }

    func removeFromWishlist(productID: Int, completion: @escaping () -> Void) {
        send("DELETE", "/api/store/wishlist/items/\(productID)") { _, _ in
            completion()
        }
    }

    // MARK: - Checkout

    /// Saves the delivery address. A rejected address still lets the order go ahead — the store keeps
    /// the address locally either way — so the completion only reports whether the backend took it.
    func saveAddress(_ address: ECAddress, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = [
            "name": address.name,
            "phone": address.phone,
            "pincode": address.pincode,
            "line": address.line,
            "city": address.city,
            "type": address.type
        ]
        send("POST", "/api/store/addresses", body: body) { _, succeeded in
            completion(succeeded)
        }
    }

    /// Authorises the payment. The server declines attempt 1 with a 502 and accepts the retry, so the
    /// run captures a genuinely failed request — an errored resource and span on the app side, an
    /// errored transaction on the backend — without the store reporting an error itself.
    func authorizePayment(amount: Double, method: ECPaymentMethod, attempt: Int, completion: @escaping (Bool) -> Void) {
        logger.info("Authorizing \(method.rawValue) payment attempt \(attempt) for amount: \(amount)")
        let body: [String: Any] = ["amount": amount, "currency": "INR", "method": method.rawValue, "attempt": attempt]
        send("POST", "/api/store/payments/authorize", body: body) { [weak self] _, succeeded in
            if succeeded {
                self?.logger.info("Payment authorized successfully")
            } else {
                self?.logger.error("Payment authorization failed on attempt \(attempt)")
            }
            completion(succeeded)
        }
    }

    /// Creates the order and returns the receipt the backend assigned it.
    func placeOrder(lines: [ECCartLine], address: ECAddress, paymentMethod: ECPaymentMethod, completion: @escaping (ECOrderReceipt?) -> Void) {
        let products = lines.map { ["productId": $0.product.id, "quantity": $0.quantity] }
        let body: [String: Any] = ["products": products, "pincode": address.pincode, "paymentMethod": paymentMethod.rawValue]
        send("POST", "/api/store/orders", body: body) { [weak self] data, succeeded in
            guard succeeded, let receipt = Self.decode(ECOrderReceipt.self, from: data) else {
                self?.logger.error("Order creation failed")
                completion(nil)
                return
            }
            self?.logger.info("Order placed successfully with reference: \(receipt.reference)")
            completion(receipt)
        }
    }

    private struct TrackingResponse: Decodable {
        let steps: [ECTrackingStep]
    }

    func loadTracking(reference: String, deliveryDays: Int, completion: @escaping ([ECTrackingStep]) -> Void) {
        get("/api/store/orders/\(reference)/tracking") { data in
            completion(Self.decode(TrackingResponse.self, from: data)?.steps ?? Self.fallbackTracking(deliveryDays: deliveryDays))
        }
    }

    /// The timeline a just-placed order has: ordered, and everything after it still to come.
    private static func fallbackTracking(deliveryDays: Int) -> [ECTrackingStep] {
        [
            ECTrackingStep(title: "Order Confirmed", detail: "Today", isComplete: true),
            ECTrackingStep(title: "Packed", detail: "Expected by tomorrow", isComplete: false),
            ECTrackingStep(title: "Shipped", detail: "Expected by \(ECDates.deliveryDate(inDays: max(deliveryDays - 2, 1)))", isComplete: false),
            ECTrackingStep(title: "Out for Delivery", detail: "Expected by \(ECDates.deliveryDate(inDays: deliveryDays))", isComplete: false),
            ECTrackingStep(title: "Delivered", detail: "Expected by \(ECDates.deliveryDate(inDays: deliveryDays))", isComplete: false)
        ]
    }

    // MARK: - Transport

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        data.flatMap { try? JSONDecoder().decode(type, from: $0) }
    }

    private func get(_ path: String, query: [URLQueryItem] = [], completion: @escaping (Data?) -> Void) {
        send(URLRequest(url: url(path, query: query))) { data, _ in completion(data) }
    }

    private func send(_ method: String, _ path: String, body: [String: Any]? = nil, completion: @escaping (Data?, Bool) -> Void) {
        var request = URLRequest(url: url(path))
        request.httpMethod = method
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        send(request, completion: completion)
    }

    private func send(_ request: URLRequest, completion: @escaping (Data?, Bool) -> Void) {
        var mutableRequest = request
        mutableRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        session.dataTask(with: mutableRequest) { data, response, error in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let succeeded = (200..<400).contains(statusCode)
            if let error = error {
                print("[ECStoreAPI] Network request error for \(mutableRequest.url?.absoluteString ?? ""): \(error)")
            } else if !succeeded {
                print("[ECStoreAPI] Network request failed with status \(statusCode) for \(mutableRequest.url?.absoluteString ?? "")")
            }
            // Back to the main queue: every caller updates the UI with the result.
            DispatchQueue.main.async {
                completion(succeeded ? data : nil, succeeded)
            }
        }
        .resume()
    }

    private func url(_ path: String, query: [URLQueryItem] = []) -> URL {
        let url = URL(string: Self.baseURL.absoluteString + path) ?? Self.baseURL
        guard !query.isEmpty, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.queryItems = query
        return components.url ?? url
    }
}
