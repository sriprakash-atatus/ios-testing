/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

/// Builds `URLRequest` for sending data to Atatus.
public struct URLRequestBuilder {
    public enum QueryItem {
        // ATCHG: Renamed the `ddsource` query parameter to `atatus_source` (Android: `QUERY_PARAM_SOURCE`).
        /// `atatus_source={source}` query item
        case atatusSource(source: String)
        // ATCHG: Renamed the `ddtags` query parameter to `atatustags` (Android: `QUERY_PARAM_TAGS`).
        /// `atatustags={tag1},{tag2},...` query item
        case atatusTags(tags: [String])
        // ATCHG: Added the Atatus identification query items sent on every upload
        // (Android: `QUERY_PARAM_CLIENT_TOKEN`, `QUERY_PARAM_AGENT_NAME`,
        // `QUERY_PARAM_AGENT_VERSION`, `QUERY_PARAM_APP_NAME`).
        /// `license_key={licenseKey}` query item
        case licenseKey(licenseKey: String)
        /// `agent_name={agentName}` query item
        case agentName(agentName: String)
        /// `agent_version={agentVersion}` query item
        case agentVersion(agentVersion: String)
        /// `app_name={appName}` query item
        case appName(appName: String)
        // ATCHG: End
    }

    public struct HTTPHeader {
        public static let contentTypeHeaderField = "Content-Type"
        public static let contentEncodingHeaderField = "Content-Encoding"
        public static let userAgentHeaderField = "User-Agent"
        // ATCHG: Renamed the dd intake headers to their Atatus equivalents
        // (Android `RequestFactory`: `HEADER_API_KEY`, `HEADER_EVP_ORIGIN`,
        // `HEADER_EVP_ORIGIN_VERSION`, `HEADER_REQUEST_ID`, `AT_IDEMPOTENCY_KEY`,
        // and `HEADER_CLIENT_TOKEN` in the flags request factory).
        public static let atAPIKeyHeaderField = "api-key"
        public static let atClientTokenHeaderField = "atatus-client-token"
        public static let atEVPOriginHeaderField = "ATATUS-EVP-ORIGIN"
        public static let atEVPOriginVersionHeaderField = "ATATUS-EVP-ORIGIN-VERSION"
        public static let atRequestIDHeaderField = "ATATUS-REQUEST-ID"
        public static let atIdempotencyKeyHeaderField = "AT-IDEMPOTENCY-KEY"
        // ATCHG: End
        // ATCHG: Added the agent identification headers sent on every upload
        // (Android: `HEADER_AGENT_NAME`, `HEADER_AGENT_VERSION`, `ATATUS_VARIANT_APP_NAME`).
        public static let atatusAgentNameHeaderField = "ATATUS-AGENT-NAME"
        public static let atatusAgentVersionHeaderField = "ATATUS-AGENT-VERSION"
        public static let atatusAppNameHeaderField = "ATATUS-APP-NAME"
        // ATCHG: End

        public enum ContentType {
            case applicationJSON
            case textPlainUTF8
            case multipartFormData(boundary: String)

            public var toString: String {
                switch self {
                case .applicationJSON: return "application/json"
                case .textPlainUTF8: return "text/plain;charset=UTF-8"
                case .multipartFormData(let boundary): return "multipart/form-data; boundary=\(boundary)"
                }
            }
        }

        let field: String
        let value: () -> String

        public init(field: String, value: @escaping () -> String) {
            self.field = field
            self.value = value
        }

        // MARK: - Standard Headers

        /// Standard "Content-Type" header.
        public static func contentTypeHeader(contentType: ContentType) -> HTTPHeader {
            return HTTPHeader(field: contentTypeHeaderField, value: { contentType.toString })
        }

        /// Standard "User-Agent" header.
        public static func userAgentHeader(
            appName: String,
            appVersion: String,
            device: DeviceInfo,
            os: OperatingSystem
        ) -> HTTPHeader {
            var sanitizedAppName = appName

            if let regex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9 -]+") {
                sanitizedAppName = regex.stringByReplacingMatches(
                    in: appName,
                    range: NSRange(appName.startIndex..<appName.endIndex, in: appName),
                    withTemplate: ""
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let agent = "\(sanitizedAppName)/\(appVersion) CFNetwork (\(device.name); \(os.name)/\(os.version))"
            return HTTPHeader(field: userAgentHeaderField, value: { agent })
        }

        // MARK: - Atatus Headers

        /// Atatus request authentication header.
        public static func atAPIKeyHeader(licenseKey: String) -> HTTPHeader {
            return HTTPHeader(field: atAPIKeyHeaderField, value: { licenseKey })
        }

        /// Atatus client token authentication header.
        public static func atClientTokenHeader(licenseKey: String) -> HTTPHeader {
            return HTTPHeader(field: atClientTokenHeaderField, value: { licenseKey })
        }

        /// An observability and troubleshooting Atatus header for tracking the origin which is sending the request.
        public static func atEVPOriginHeader(source: String) -> HTTPHeader {
            return HTTPHeader(field: atEVPOriginHeaderField, value: { source })
        }

        /// An observability and troubleshooting Atatus header for tracking the origin which is sending the request.
        public static func atEVPOriginVersionHeader(sdkVersion: String) -> HTTPHeader {
            return HTTPHeader(field: atEVPOriginVersionHeaderField, value: { sdkVersion })
        }

        /// An optional Atatus header for debugging Intake requests by their ID.
        public static func atRequestIDHeader() -> HTTPHeader {
            return HTTPHeader(field: atRequestIDHeaderField, value: { UUID().uuidString })
        }

        /// An optional Atatus header for ensuring idempotent requests.
        /// - Parameter key: The idempotency key.
        /// - Returns: Header with the idempotency key.
        public static func atIdempotencyKeyHeader(key: String) -> HTTPHeader {
            return HTTPHeader(field: atIdempotencyKeyHeaderField, value: { key })
        }

        // ATCHG: Added the agent identification headers, mirroring `buildHeaders()` in
        // Android's `LogsRequestFactory` (`HEADER_AGENT_NAME`, `HEADER_AGENT_VERSION`,
        // `ATATUS_VARIANT_APP_NAME`).
        /// The name of the agent sending the request, e.g. `"Atatus iOS Agent"`.
        public static func atatusAgentNameHeader(agentName: String = AgentInfo.agentName) -> HTTPHeader {
            return HTTPHeader(field: atatusAgentNameHeaderField, value: { agentName })
        }

        /// The version of the agent sending the request.
        public static func atatusAgentVersionHeader(agentVersion: String = AgentInfo.agentVersion) -> HTTPHeader {
            return HTTPHeader(field: atatusAgentVersionHeaderField, value: { agentVersion })
        }

        /// The name of the instrumented application.
        public static func atatusAppNameHeader(appName: String) -> HTTPHeader {
            return HTTPHeader(field: atatusAppNameHeaderField, value: { appName })
        }
        // ATCHG: End
    }
    /// Upload `URL`.
    private let url: URL
    /// HTTP headers.
    private let headers: [HTTPHeader]
    /// Telemetry interface.
    private let telemetry: Telemetry

    // MARK: - Initialization

    public init(
        url: URL,
        queryItems: [QueryItem],
        headers: [HTTPHeader],
        telemetry: Telemetry = NOPTelemetry()
    ) {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems.map { .init($0) }
        }

        self.url = urlComponents?.url ?? url
        self.headers = headers
        self.telemetry = telemetry
    }

    /// Creates `URLRequest` for uploading given `body` to Atatus.
    ///
    /// - Parameter body: HTTP body to be attached to request
    /// - Parameter compress: if `body` should be compressed into ZLIB Compressed Data Format (IETF RFC 1950)
    /// - Returns: the `URLRequest` object.
    public func uploadRequest(with body: Data, compress: Bool = true) -> URLRequest {
        var request = URLRequest(url: url)
        var headers: [String: String] = [:]
        self.headers.forEach { headers[$0.field] = $0.value() }
        request.httpMethod = "POST"

        if compress, let deflatedBody = Deflate.encode(body) {
            headers[HTTPHeader.contentEncodingHeaderField] = "deflate"
            request.httpBody = deflatedBody
        } else {
            request.httpBody = body
            if compress {
                telemetry.debug(
                    """
                    Failed to compress request payload
                    - url: \(url)
                    - uncompressed-size: \(body.count)
                    """
                )
            }
        }

        headers.forEach { field, value in
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}

extension URLQueryItem {
    init(_ query: URLRequestBuilder.QueryItem) {
        switch query {
        // ATCHG: Renamed the intake query parameters and added the Atatus identification
        // parameters, mirroring `RequestFactory` in the Atatus Android agent.
        case .atatusSource(let source):
            self = URLQueryItem(name: "atatus_source", value: source)
        case .atatusTags(let tags):
            self = URLQueryItem(name: "atatustags", value: tags.joined(separator: ","))
        case .licenseKey(let licenseKey):
            self = URLQueryItem(name: "license_key", value: licenseKey)
        case .agentName(let agentName):
            self = URLQueryItem(name: "agent_name", value: agentName)
        case .agentVersion(let agentVersion):
            self = URLQueryItem(name: "agent_version", value: agentVersion)
        case .appName(let appName):
            self = URLQueryItem(name: "app_name", value: appName)
        // ATCHG: End
        }
    }
}
