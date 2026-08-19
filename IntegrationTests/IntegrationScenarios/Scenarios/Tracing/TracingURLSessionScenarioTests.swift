/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `_dd` attribute prefix to `_atatus`; renamed the `x-dd-*` trace headers to `x-atatus-*`; rebranded
// the licence header.

import AtatusInternal
import HTTPServerMock
import TestUtilities
import XCTest

private extension ExampleApplication {
    func tapSend3rdPartyRequests() {
        buttons["Send 3rd party requests"].tap()
    }
}

class TracingURLSessionScenarioTests: IntegrationTests, TracingCommonAsserts {
    func testTracingURLSessionScenario_delegateUsingFeatureFirstPartyHosts() throws {
        try runTest(
            for: "TracingURLSessionScenario",
            urlSessionSetup: .init(
                instrumentationMethod: .delegateUsingFeatureFirstPartyHosts,
                initializationMethod: .afterSDK
            )
        )
    }

    func testTracingURLSessionScenario_delegateWithAdditionalFirstyPartyHosts() throws {
        try runTest(
            for: "TracingURLSessionScenario",
            urlSessionSetup: .init(
                instrumentationMethod: .delegateWithAdditionalFirstPartyHosts,
                initializationMethod: .afterSDK
            )
        )
    }

    func testTracingNSURLSessionScenario_delegateUsingFeatureFirstPartyHosts() throws {
        try runTest(
            for: "TracingNSURLSessionScenario",
            urlSessionSetup: .init(
                instrumentationMethod: .delegateUsingFeatureFirstPartyHosts,
                initializationMethod: .afterSDK
            )
        )
    }

    func testTracingNSURLSessionScenario_delegateWithAdditionalFirstyPartyHosts() throws {
        try runTest(
            for: "TracingNSURLSessionScenario",
            urlSessionSetup: .init(
                instrumentationMethod: .delegateWithAdditionalFirstPartyHosts,
                initializationMethod: .afterSDK
            )
        )
    }

    /// Validates that the Trace feature reports the **full 128-bit** trace ID on the wire, and that it is
    /// byte-for-byte the ID propagated to the backend in the W3C `traceparent` header.
    ///
    /// Regression coverage: spans used to be encoded with only the low 64 bits of the trace ID, so the
    /// mobile span and the backend span for the same request carried different `trace_id` values and were
    /// indexed as two unrelated traces. The high 64 bits were only recoverable from `meta._atatus.p.tid`.
    ///
    /// This test asserts the reported ID only. Propagation itself is unchanged and is pinned below, so a
    /// regression in either direction fails here.
    func testTracingURLSessionScenario_reportsFull128BitTraceIDMatchingTraceparent() throws {
        // Server session recording first party requests sent to `HTTPServerMock`.
        let customFirstPartyServerSession = server.obtainUniqueRecordingSession()
        // Server session recording `Spans` sent to `HTTPServerMock`.
        let tracingServerSession = server.obtainUniqueRecordingSession()

        let firstPartyGETResourceURL = URL(
            string: customFirstPartyServerSession.recordingURL.deletingLastPathComponent().absoluteString + "inspect"
        )!
        let firstPartyPOSTResourceURL = customFirstPartyServerSession.recordingURL
        let firstPartyBadResourceURL = URL(string: "https://foo.bar/")!
        let thirdPartyGETResourceURL = URL(string: "https://bitrise.io")!
        let thirdPartyPOSTResourceURL = URL(string: "https://bitrise.io/about")!

        let app = ExampleApplication()
        app.launchWith(
            testScenarioClassName: "TracingURLSessionScenario",
            serverConfiguration: HTTPServerMockConfiguration(
                tracesEndpoint: tracingServerSession.recordingURL,
                instrumentedEndpoints: [
                    firstPartyGETResourceURL,
                    firstPartyPOSTResourceURL,
                    firstPartyBadResourceURL,
                    thirdPartyGETResourceURL,
                    thirdPartyPOSTResourceURL
                ]
            ),
            urlSessionSetup: .init(
                instrumentationMethod: .delegateUsingFeatureFirstPartyHosts,
                initializationMethod: .afterSDK
            )
        )
        app.tapSend3rdPartyRequests()

        let recordedTracingRequests = try tracingServerSession.pullRecordedRequests(timeout: dataDeliveryTimeout) { requests in
            try SpanMatcher.from(requests: requests).count >= 3
        }
        let spanMatchers = try SpanMatcher.from(requests: recordedTracingRequests)

        let span = try XCTUnwrap(
            spanMatchers.first { span in try span.resource() == firstPartyPOSTResourceURL.absoluteString },
            "`SpanEvent` should be sent for `firstPartyPOSTResourceURL`"
        )

        // 1. `trace_id` must carry the whole 128-bit ID, zero-padded to 32 lowercase hex characters.
        let reportedTraceID = try span.traceIDString()
        XCTAssertTrue(
            reportedTraceID.matches(regex: "^[0-9a-f]{32}$"),
            "`trace_id` must be the 128-bit ID as 32 lowercase hex characters, got '\(reportedTraceID)'"
        )

        // 2. The high 64 bits must survive. A truncated ID zeroes them out here while `_atatus.p.tid`
        // still carries them, which is exactly the split that broke backend correlation.
        let traceID = try XCTUnwrap(span.traceID(), "`trace_id` should be parsable as `TraceID`")
        XCTAssertNotEqual(traceID.idHi, TraceID.invalidId, "The high 64 bits of the trace ID must not be truncated away")
        XCTAssertEqual(String(reportedTraceID.prefix(16)), String(format: "%016llx", traceID.idHi))
        XCTAssertEqual(String(reportedTraceID.suffix(16)), String(format: "%016llx", traceID.idLo))

        // 3. `meta._atatus.p.tid` keeps carrying the same high 64 bits, for backwards compatibility.
        let tid = try span.meta.tid()
        XCTAssertEqual(
            UInt64(tid, radix: 16),
            traceID.idHi,
            "`_atatus.p.tid` must stay consistent with the high 64 bits of `trace_id`"
        )

        // 4. The ID the agent reports must equal the ID it propagated to the backend, so the mobile
        // span and the backend span for this request correlate into a single distributed trace.
        let firstPartyRequests = try customFirstPartyServerSession
            .pullRecordedRequests(timeout: dataDeliveryTimeout) { $0.count >= 1 }
        let firstPartyRequest = try XCTUnwrap(firstPartyRequests.first)

        let traceparent = try XCTUnwrap(
            firstPartyRequest.httpHeaders["traceparent"],
            "The instrumented first party request must carry a W3C `traceparent` header"
        )
        let traceparentFields = traceparent.split(separator: "-").map(String.init)
        XCTAssertEqual(traceparentFields.count, 4, "Malformed `traceparent`: '\(traceparent)'")
        XCTAssertEqual(
            traceparentFields[1],
            reportedTraceID,
            "`trace_id` reported by the agent must equal the trace ID propagated in `traceparent`"
        )
        let spanID = try XCTUnwrap(span.spanID())
        XCTAssertEqual(traceparentFields[2], spanID.toString(representation: .hexadecimal16Chars))
        XCTAssertEqual(traceparentFields[3], "01", "The sampled first party request must propagate a sampled `traceparent`")

        // 5. Pin the legacy Atatus headers: propagation must be unchanged by the reporting fix.
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-trace-id"], String(traceID.idLo))
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-parent-id"], spanID.toString(representation: .decimal))
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-sampling-priority"], "1")
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-tags"], "_atatus.p.tid=\(tid),_atatus.p.dm=-1")
    }

    /// Both, `URLSession` (Swift) and `NSURLSession` (Objective-C) scenarios fetch exactly the same
    /// resources, so we can run the same test and assertions.
    private func runTest(for testScenarioClassName: String, urlSessionSetup: URLSessionSetup) throws {
        let testBeginTimeInNanoseconds = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)

        // Server session recording first party requests send to `HTTPServerMock`.
        // Used to assert that trace propagation headers are send for first party requests.
        let customFirstPartyServerSession = server.obtainUniqueRecordingSession()

        // Server session recording `Spans` send to `HTTPServerMock`.
        let tracingServerSession = server.obtainUniqueRecordingSession()

        // Requesting this first party by the app should create the `SpanEvent`.
        let firstPartyGETResourceURL = URL(
            string: customFirstPartyServerSession.recordingURL.deletingLastPathComponent().absoluteString + "inspect"
        )!
        // Requesting this first party by the app should create the `SpanEvent`.
        let firstPartyPOSTResourceURL = customFirstPartyServerSession.recordingURL
        // Requesting this first party by the app should create the `SpanEvent` with error.
        let firstPartyBadResourceURL = URL(string: "https://foo.bar/")!

        // Requesting this third party by the app should NOT create the `SpanEvent`.
        let thirdPartyGETResourceURL = URL(string: "https://bitrise.io")!
        // Requesting this third party by the app should NOT create the `SpanEvent`.
        let thirdPartyPOSTResourceURL = URL(string: "https://bitrise.io/about")!

        let app = ExampleApplication()
        app.launchWith(
            testScenarioClassName: testScenarioClassName,
            serverConfiguration: HTTPServerMockConfiguration(
                tracesEndpoint: tracingServerSession.recordingURL,
                instrumentedEndpoints: [
                    firstPartyGETResourceURL,
                    firstPartyPOSTResourceURL,
                    firstPartyBadResourceURL,
                    thirdPartyGETResourceURL,
                    thirdPartyPOSTResourceURL
                ]
            ),
            urlSessionSetup: urlSessionSetup
        )
        app.tapSend3rdPartyRequests()

        // Get expected number of `SpanMatchers`
        let recordedTracingRequests = try tracingServerSession.pullRecordedRequests(timeout: dataDeliveryTimeout) { requests in
            try SpanMatcher.from(requests: requests).count >= 3
        }
        let spanMatchers = try SpanMatcher.from(requests: recordedTracingRequests)

        assertTracing(requests: recordedTracingRequests)

        let testEndTimeInNanoseconds = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
        try assertCommonMetadata(in: spanMatchers)
        try assertThat(spans: spanMatchers, startAfter: testBeginTimeInNanoseconds, andFinishBefore: testEndTimeInNanoseconds)

        let taskWithURL = try XCTUnwrap(
            spanMatchers.first { span in try span.resource() == firstPartyGETResourceURL.absoluteString },
            "`SpanEvent` should be send for `firstPartyGETResourceURL`"
        )
        let taskWithRequest = try XCTUnwrap(
            spanMatchers.first { span in try span.resource() == firstPartyPOSTResourceURL.absoluteString },
            "`SpanEvent` should be send for `firstPartyPOSTResourceURL`"
        )
        let taskWithBadURL = try XCTUnwrap(
            spanMatchers.first { span in try span.resource() == firstPartyBadResourceURL.absoluteString },
            "`SpanEvent` should be send for `firstPartyBadResourceURL`"
        )
        try XCTAssertFalse(
            spanMatchers.contains { span in try span.resource() == thirdPartyGETResourceURL.absoluteString },
            "`SpanEvent` should NOT bet send for `thirdPartyGETResourceURL`"
        )
        try XCTAssertFalse(
            spanMatchers.contains { span in try span.resource() == thirdPartyPOSTResourceURL.absoluteString },
            "`SpanEvent` should NOT bet send for `thirdPartyPOSTResourceURL`"
        )

        XCTAssertEqual(try taskWithURL.operationName(), "urlsession.request")
        XCTAssertEqual(try taskWithRequest.operationName(), "urlsession.request")
        XCTAssertEqual(try taskWithBadURL.operationName(), "urlsession.request")

        XCTAssertEqual(try taskWithURL.meta.custom(keyPath: "meta.http.url"), "redacted")
        XCTAssertEqual(try taskWithRequest.meta.custom(keyPath: "meta.http.url"), "redacted")
        XCTAssertEqual(try taskWithBadURL.meta.custom(keyPath: "meta.http.url"), "redacted")

        XCTAssertEqual(try taskWithURL.metrics.isRootSpan(), 1)
        XCTAssertEqual(try taskWithRequest.metrics.isRootSpan(), 1)
        XCTAssertEqual(try taskWithBadURL.metrics.isRootSpan(), 1)

        XCTAssertEqual(try taskWithURL.isError(), 0)
        XCTAssertEqual(try taskWithRequest.isError(), 0)
        XCTAssertEqual(try taskWithBadURL.isError(), 1)

        XCTAssertGreaterThan(try taskWithURL.duration(), 0)
        XCTAssertGreaterThan(try taskWithRequest.duration(), 0)
        XCTAssertGreaterThan(try taskWithBadURL.duration(), 0)

        // Assert tracing HTTP headers propagated to `firstPartyPOSTResourceURL`
        let firstPartyRequests = try customFirstPartyServerSession
            .pullRecordedRequests(timeout: dataDeliveryTimeout) { $0.count >= 1 }

        XCTAssertEqual(firstPartyRequests.count, 1)

        let firstPartyRequest = firstPartyRequests[0]
        let traceId = try taskWithRequest.traceID() ?? .invalid
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-trace-id"], String(traceId.idLo))
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-parent-id"], try taskWithRequest.spanID()?.toString(representation: .decimal))
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-sampling-priority"], "1")
        XCTAssertNil(firstPartyRequest.httpHeaders["x-atatus-origin"])
        let tid = try taskWithRequest.meta.tid()
        XCTAssertEqual(firstPartyRequest.httpHeaders["x-atatus-tags"], "_atatus.p.tid=\(tid),_atatus.p.dm=-1")
    }
}
