/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` members to `at*`; renamed the `x-dd-*` trace headers to
// `x-atatus-*`; removed the `dd` name from comments and docs; rebranded the licence header.

import Foundation

/// An immutable version of `URLRequest`.
///
/// Introduced in response to concerns raised in https://github.com/dd/atatus-sdk-ios/issues/1638
/// it makes a copy of request attributes, safeguarding against potential thread safety issues arising from concurrent
/// mutations (see more context in https://github.com/dd/atatus-sdk-ios/pull/1767 ).
public struct ImmutableRequest {
    /// The URL of the request.
    public let url: URL?
    /// The HTTP method of the request.
    public let httpMethod: String?
    /// The value of `x-atatus-origin` header (if any).
    public let atOriginHeaderValue: String?
    /// A reference to the original `URLRequest` object provided during initialization. Direct use is discouraged
    /// due to thread safety concerns. Instead, necessary attributes should be accessed through `ImmutableRequest` fields.
    public let unsafeOriginal: URLRequest

    public init(request: URLRequest) {
        self.url = request.url
        self.httpMethod = request.httpMethod
        // RUM-3183: As observed in https://github.com/dd/atatus-sdk-ios/issues/1638, accessing `request.allHTTPHeaderFields` is not
        // safe and can lead to crashes with undefined root cause. To avoid issues we should prefer `request.value(forHTTPHeaderField:)`
        // when interacting with `URLRequest`.
        self.atOriginHeaderValue = request.value(forHTTPHeaderField: TracingHTTPHeaders.originField)
        self.unsafeOriginal = request
    }
}
