/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// The app runs on mock services today. This is the seam a REST backend plugs into: each service
// protocol gets a `Remote…` implementation built on `APIClient`, and `AppServices` swaps it in.

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem]
    var body: Data?
    var headers: [String: String]

    init(path: String, method: HTTPMethod = .get, queryItems: [URLQueryItem] = [], body: Data? = nil, headers: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }

    /// An endpoint whose body is `value`, JSON-encoded.
    static func json<Body: Encodable>(_ path: String, method: HTTPMethod, body value: Body) throws -> Endpoint {
        Endpoint(
            path: path,
            method: method,
            body: try JSONEncoder.api.encode(value),
            headers: ["Content-Type": "application/json"]
        )
    }
}

enum APIError: LocalizedError, Equatable, Sendable {
    case offline
    case timeout
    case unauthorized(message: String)
    case notFound
    case server(statusCode: Int)
    case decoding
    case validation(message: String)
    case paymentDeclined(message: String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .offline: return "You appear to be offline. Check your connection and try again."
        case .timeout: return "The request took too long. Please try again."
        case .unauthorized(let message): return message
        case .notFound: return "We couldn't find what you were looking for."
        case .server: return "Something went wrong on our side. Please try again in a moment."
        case .decoding: return "We received an unexpected response. Please try again."
        case .validation(let message): return message
        case .paymentDeclined(let message): return message
        case .unknown: return "Something went wrong. Please try again."
        }
    }

    /// A message for any error a service throws, falling back to a generic one.
    static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? APIError.unknown.errorDescription ?? "Something went wrong."
    }
}

protocol APIClient: Sendable {
    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response
}

/// `APIClient` over `URLSession`, for when the mock services are replaced by a real backend.
final class URLSessionAPIClient: APIClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: @Sendable () -> String?

    init(baseURL: URL, session: URLSession = .shared, tokenProvider: @escaping @Sendable () -> String? = { nil }) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
    }

    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        let request = try makeRequest(for: endpoint)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost: throw APIError.offline
            case .timedOut: throw APIError.timeout
            default: throw APIError.unknown
            }
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw APIError.unauthorized(message: "Your session has expired. Please sign in again.")
        case 404:
            throw APIError.notFound
        default:
            throw APIError.server(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder.api.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw APIError.unknown
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else {
            throw APIError.unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

/// Simulated network conditions for the mock services.
enum MockNetwork {
    /// How long a typical mock request takes, in seconds.
    static let typicalLatency: ClosedRange<Double> = 0.35...0.9

    static func delay(_ range: ClosedRange<Double> = typicalLatency) async throws {
        let seconds = Double.random(in: range)
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
