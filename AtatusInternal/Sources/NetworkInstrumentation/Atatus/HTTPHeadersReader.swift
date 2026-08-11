/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `_dd` attribute prefix to `_atatus`; rebranded the licence
// header.

import Foundation

public class HTTPHeadersReader: TracePropagationHeadersReader {
    private let httpHeaderFields: [String: String]

    public init(httpHeaderFields: [String: String]) {
        self.httpHeaderFields = httpHeaderFields
    }

    public func read() -> (traceID: TraceID, spanID: SpanID, parentSpanID: SpanID?)? {
        guard let traceIDLoValue = httpHeaderFields[TracingHTTPHeaders.traceIDField],
              let spanIDValue = httpHeaderFields[TracingHTTPHeaders.parentSpanIDField],
              let spanID = SpanID(spanIDValue, representation: .decimal)
        else {
            return nil
        }

        // tags are comma separated key=value pairs
        let tags = httpHeaderFields[TracingHTTPHeaders.tagsField]?.split(separator: ",")
            .map { $0.split(separator: "=") }
            .reduce(into: [String: String]()) { result, pair in
                if pair.count == 2 {
                    result[String(pair[0])] = String(pair[1])
                }
            } ?? [:]

        let traceIDHiValue = tags[TracingHTTPHeaders.TagKeys.traceIDHi] ?? "0"

        let traceID = TraceID(
            idHi: UInt64(traceIDHiValue, radix: 16) ?? 0,
            idLo: UInt64(traceIDLoValue, radix: 10) ?? 0
        )

        return (
            traceID: traceID,
            spanID: spanID,
            parentSpanID: nil
        )
    }

    public var samplingPriority: SamplingPriority? {
        guard let sampling = httpHeaderFields[TracingHTTPHeaders.samplingPriorityField] else {
            return nil
        }

        return SamplingPriority(string: sampling)
    }

    public var samplingDecisionMaker: SamplingMechanismType? {
        guard let tagsField = httpHeaderFields[TracingHTTPHeaders.tagsField] else {
            return nil
        }

        let tags = tagsField.split(separator: ",")

        return tags.lazy
            .compactMap {
                guard
                    case let tagElements = $0.split(separator: "="),
                    tagElements.count == 2,
                    let key = tagElements.first,
                    key == "_atatus.p.dm",
                    case let value = tagElements[1],
                    let tagValue = Self.parseDecisionMakerTag(fromValue: value),
                    let mechanismType = SamplingMechanismType(rawValue: String(tagValue))
                else { return nil }
                return mechanismType
            }
            .first
    }
}
