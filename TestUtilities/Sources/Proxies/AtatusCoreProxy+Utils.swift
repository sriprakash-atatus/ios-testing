/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddLogs`
// -> `AtatusLogs`, `ddRUM` -> `AtatusRUM`, `ddTrace` -> `AtatusTrace`; renamed `dd*` types
// to `Atatus*`; rebranded the licence header.

import Foundation

@testable import AtatusLogs
@testable import AtatusRUM
@testable import AtatusTrace
@testable import AtatusInternal

extension AtatusCoreProxy {
    public func waitAndReturnSpanMatchers(file: StaticString = #file, line: UInt = #line) throws -> [SpanMatcher] {
        return try waitAndReturnEventsData(ofFeature: TraceFeature.name)
            .map { eventData in try SpanMatcher.fromJSONObjectData(eventData) }
    }

    public func waitAndReturnSpanEvents(file: StaticString = #file, line: UInt = #line) -> [SpanEvent] {
        return waitAndReturnEvents(ofFeature: TraceFeature.name, ofType: SpanEventsEnvelope.self)
            .map { envelope in
                precondition(envelope.spans.count == 1, "Only expect one `SpanEvent` per envelope")
                return envelope.spans[0]
            }
    }
}

extension AtatusCoreProxy {
    public func waitAndReturnLogMatchers(file: StaticString = #file, line: UInt = #line) throws -> [LogMatcher] {
        return try waitAndReturnEventsData(ofFeature: LogsFeature.name)
            .map { data in try LogMatcher.fromJSONObjectData(data) }
    }
}

extension AtatusCoreProxy {
    public func waitAndReturnRUMEventMatchers(file: StaticString = #file, line: UInt = #line) throws -> [RUMEventMatcher] {
        return try waitAndReturnEventsData(ofFeature: RUMFeature.name)
            .map { data in try RUMEventMatcher.fromJSONObjectData(data) }
    }
}
