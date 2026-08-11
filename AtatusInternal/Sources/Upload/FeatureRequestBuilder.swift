/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `ddsource` / `ddtags`
// query parameters to `atatus_source` / `atatustags`; rebranded the `dd` name to `Atatus` in comments
// and docs; rebranded the licence header.

import Foundation

/// The `FeatureRequestBuilder` defines an interface for building a single `URLRequest`
/// for a list of data events and the current core context.
///
/// A Feature should use this interface for creating requests that needs be sent to its Atatus Intake.
/// The request will be transported by `AtatusCore`.
public protocol FeatureRequestBuilder {
    /// Builds an `URLRequest` for a list of events and the current core context to be uploaded
    /// to the Feature's Intake.
    ///
    /// The returned request must include all necessary information, i.e. HTTP headers and
    /// URL queries required by the Feature's Intake. The request will be sent by the core.
    ///
    /// **Note:** When `Error` is thrown, underlying data will be dropped permanently and never retried. The
    /// implementation should make a wise consideration of throwing vs recovering strategy.
    ///
    /// - Parameters:
    ///   - context: The current core context.
    ///   - events: The events data to be uploaded.
    /// - Returns: The URL request.
    func request(
        for events: [Event],
        with context: AtatusContext,
        execution: ExecutionContext
    ) throws -> URLRequest
}

/// Represents the context in which the request is being executed.
public struct ExecutionContext {
    /// HTTP status code of the previous response.
    public let previousResponseCode: Int?

    /// The current attempt number.
    public let attempt: UInt

    /// Tags to include in the request when this is a retry attempt.
    /// Returns `nil` on the first request (`attempt == 0`).
    private var retryTags: [String]? {
        guard attempt > 0 else {
            return nil
        }
        var tags = ["retry_count:\(attempt)"]
        if let code = previousResponseCode {
            tags.append("retry_after:\(code)")
        }
        return tags
    }

    /// Query items to include in the request when this is a retry attempt.
    /// Returns an empty array on the first request (`attempt == 0`).
    public var retryQueryItems: [URLRequestBuilder.QueryItem] {
        retryTags.map { [.atatusTags(tags: $0)] } ?? []
    }

    /// Initializes the execution context.
    /// - Parameters:
    ///   - previousResponseCode: Previous HTTP status code, if available.
    ///   - attempt: The current attempt number.
    public init(
        previousResponseCode: Int?,
        attempt: UInt
    ) {
        self.previousResponseCode = previousResponseCode
        self.attempt = attempt
    }
}
