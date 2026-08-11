/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation
import OpenTelemetryApi

/// Represents a span link containing a `SpanContext` and additional attributes.
internal struct OTelSpanLink: Equatable, Sendable {
    /// Context of the linked span.
    let context: OpenTelemetryApi.SpanContext

    /// Additional attributes of the linked span.
    let attributes: [String: OpenTelemetryApi.AttributeValue]
}

extension OTelSpanLink: Encodable {
    enum CodingKeys: String, CodingKey {
        case traceId = "trace_id"
        case spanId = "span_id"
        case attributes = "attributes"
        case traceState = "tracestate"
        case traceFlags = "flags"
    }

    /// Encodes the span link to the following JSON format:
    /// ```json
    ///  {
    ///     "trace_id": "<exactly 32 character, zero-padded lower-case hexadecimal encoded trace id>",
    ///     "span_id": "<exactly 16 character, zero-padded lower-case hexadecimal encoded span id>",
    ///     "attributes": {"key":"value", "pairs":"of", "arbitrary":"values"},
    ///     "dropped_attributes_count": <decimal 64 bit integer>,
    ///     "tracestate": "a tracestate as defined in the W3C standard",
    ///     "flags": <an integer representing the flags as defined in the W3C standard>
    /// },
    /// ```
    /// - Parameter encoder: Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let traceId = String(context.traceId.toAtatus(), representation: .hexadecimal32Chars)

        try container.encode(traceId, forKey: .traceId)
        try container.encode(context.spanId.hexString, forKey: .spanId)
        if !attributes.isEmpty {
            try container.encode(attributes.tags, forKey: .attributes)
        }

        if !context.traceState.entries.isEmpty {
            try container.encode(context.traceState.w3c(), forKey: .traceState)
        }
        try container.encode(context.traceFlags.byte, forKey: .traceFlags)
    }
}
