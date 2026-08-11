/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `_dd` attribute prefix to `_atatus`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

class HTTPHeadersWriterTests: XCTestCase {
    func testWritingSampledTraceContext_withHeadBasedSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .all)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .autoKeep,
                samplingDecisionMaker: .agentRate,
                rumSessionId: "abcdef01-2345-6789-abcd-ef0123456789"
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertEqual(headers[TracingHTTPHeaders.samplingPriorityField], "1")
        XCTAssertEqual(headers[TracingHTTPHeaders.traceIDField], "1234")
        XCTAssertEqual(headers[TracingHTTPHeaders.parentSpanIDField], "2345")
        XCTAssertEqual(headers[TracingHTTPHeaders.tagsField], "_atatus.p.tid=4d2,_atatus.p.dm=-1")
        XCTAssertEqual(headers[W3CHTTPHeaders.baggage], "session.id=abcdef01-2345-6789-abcd-ef0123456789")
    }

    func testWritingDroppedTraceContext_withHeadBasedSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .autoDrop,
                samplingDecisionMaker: .agentRate
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertNil(headers[TracingHTTPHeaders.samplingPriorityField])
        XCTAssertNil(headers[TracingHTTPHeaders.traceIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.parentSpanIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.tagsField])
    }

    func testWritingManuallyKeptTraceContext_withHeadBasedSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .all)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .manualKeep,
                samplingDecisionMaker: .manual,
                rumSessionId: "abcdef01-2345-6789-abcd-ef0123456789"
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertEqual(headers[TracingHTTPHeaders.samplingPriorityField], "2")
        XCTAssertEqual(headers[TracingHTTPHeaders.traceIDField], "1234")
        XCTAssertEqual(headers[TracingHTTPHeaders.parentSpanIDField], "2345")
        XCTAssertEqual(headers[TracingHTTPHeaders.tagsField], "_atatus.p.tid=4d2,_atatus.p.dm=-4")
        XCTAssertEqual(headers[W3CHTTPHeaders.baggage], "session.id=abcdef01-2345-6789-abcd-ef0123456789")
    }

    func testWritingManuallyDroppedTraceContext_withHeadBasedSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .manualDrop,
                samplingDecisionMaker: .manual
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertNil(headers[TracingHTTPHeaders.samplingPriorityField])
        XCTAssertNil(headers[TracingHTTPHeaders.traceIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.parentSpanIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.tagsField])
    }

    func testWritingSampledTraceContext_withCustomSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .autoKeep,
                samplingDecisionMaker: .agentRate,
                rumSessionId: "abcdef01-2345-6789-abcd-ef0123456789"
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertEqual(headers[TracingHTTPHeaders.samplingPriorityField], "1")
        XCTAssertEqual(headers[TracingHTTPHeaders.traceIDField], "1234")
        XCTAssertEqual(headers[TracingHTTPHeaders.parentSpanIDField], "2345")
        XCTAssertEqual(headers[TracingHTTPHeaders.tagsField], "_atatus.p.tid=4d2,_atatus.p.dm=-1")
        XCTAssertEqual(headers[W3CHTTPHeaders.baggage], "session.id=abcdef01-2345-6789-abcd-ef0123456789")
    }

    // The sampling based on session ID should pass at 18% sampling rate and fail at 17% 
    func testWritingSampledTraceContext_withCustomSamplingStrategy_18percent() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .autoKeep,
                samplingDecisionMaker: .agentRate,
                rumSessionId: "abcdef01-2345-6789-abcd-ef0123456789"
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertEqual(headers[TracingHTTPHeaders.samplingPriorityField], "1")
        XCTAssertEqual(headers[TracingHTTPHeaders.traceIDField], "1234")
        XCTAssertEqual(headers[TracingHTTPHeaders.parentSpanIDField], "2345")
        XCTAssertEqual(headers[TracingHTTPHeaders.tagsField], "_atatus.p.tid=4d2,_atatus.p.dm=-1")
        XCTAssertEqual(headers[W3CHTTPHeaders.baggage], "session.id=abcdef01-2345-6789-abcd-ef0123456789")
    }

    func testWritingDroppedTraceContext_withCustomSamplingStrategy_17percent() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .autoDrop,
                samplingDecisionMaker: .agentRate,
                rumSessionId: "abcdef01-2345-6789-abcd-ef0123456789"
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertNil(headers[TracingHTTPHeaders.samplingPriorityField])
        XCTAssertNil(headers[TracingHTTPHeaders.traceIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.parentSpanIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.tagsField])
        XCTAssertNil(headers[W3CHTTPHeaders.baggage])
    }

    func testWritingDroppedTraceContext_withCustomSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .autoDrop,
                samplingDecisionMaker: .agentRate
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertNil(headers[TracingHTTPHeaders.samplingPriorityField])
        XCTAssertNil(headers[TracingHTTPHeaders.traceIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.parentSpanIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.tagsField])
        XCTAssertNil(headers[W3CHTTPHeaders.baggage])
    }

    func testWritingManuallyKeptTraceContext_withCustomSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .manualKeep,
                samplingDecisionMaker: .manual,
                rumSessionId: "abcdef01-2345-6789-abcd-ef0123456789"
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertEqual(headers[TracingHTTPHeaders.samplingPriorityField], "2")
        XCTAssertEqual(headers[TracingHTTPHeaders.traceIDField], "1234")
        XCTAssertEqual(headers[TracingHTTPHeaders.parentSpanIDField], "2345")
        XCTAssertEqual(headers[TracingHTTPHeaders.tagsField], "_atatus.p.tid=4d2,_atatus.p.dm=-4")
        XCTAssertEqual(headers[W3CHTTPHeaders.baggage], "session.id=abcdef01-2345-6789-abcd-ef0123456789")
    }

    func testWritingManuallyDroppedTraceContext_withCustomSamplingStrategy() {
        let writer = HTTPHeadersWriter(traceContextInjection: .sampled)

        writer.write(
            traceContext: .mockWith(
                traceID: .init(idHi: 1_234, idLo: 1_234),
                spanID: 2_345,
                samplingPriority: .manualDrop,
                samplingDecisionMaker: .manual
            )
        )

        let headers = writer.traceHeaderFields
        XCTAssertNil(headers[TracingHTTPHeaders.samplingPriorityField])
        XCTAssertNil(headers[TracingHTTPHeaders.traceIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.parentSpanIDField])
        XCTAssertNil(headers[TracingHTTPHeaders.tagsField])
        XCTAssertNil(headers[W3CHTTPHeaders.baggage])
    }
}
