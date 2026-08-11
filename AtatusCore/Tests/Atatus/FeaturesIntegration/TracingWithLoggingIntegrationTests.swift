/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`, `ddLogs` -> `AtatusLogs`, `ddTrace` -> `AtatusTrace`; renamed the `DD` symbol
// prefix to `AT`; renamed `dd.trace_id` / `dd.span_id` to `atatus.trace_id` / `atatus.span_id`; rebranded
// the licence header.

import XCTest
import AtatusInternal
import TestUtilities

@testable import AtatusLogs
@testable import AtatusTrace
@testable import AtatusCore

class TracingWithLoggingIntegrationTests: XCTestCase {
    private var core: PassthroughCoreMock! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        core = PassthroughCoreMock(messageReceiver: LogMessageReceiver.mockAny())
    }

    override func tearDown() {
        core = nil
        super.tearDown()
    }

    func testSendingLogWithOTMessageField() throws {
        let expectation = expectation(description: "Send log")
        core.onEventWriteContext = { _ in expectation.fulfill() }

        // Given
        let integration = TracingWithLoggingIntegration(core: core, service: .mockAny(), networkInfoEnabled: .mockAny())

        // When
        integration.writeLog(
            withSpanContext: .mockWith(traceID: .init(idHi: 10, idLo: 100), spanID: 200),
            fields: [
                OTLogFields.message: "hello",
                "custom field": 123,
            ],
            date: .mockDecember15th2019At10AMUTC(),
            else: {}
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let log: LogEvent = try XCTUnwrap(core.events().last, "It should send log")
        XCTAssertEqual(log.date, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(log.status, .info)
        XCTAssertEqual(log.message, "hello")
        ATAssertJSONEqual(
            AnyEncodable(log.attributes.userAttributes),
            AnyEncodable(["custom field": 123])
        )
        ATAssertJSONEqual(
            AnyEncodable(log.attributes.internalAttributes),
            AnyEncodable([
                "atatus.trace_id": "a0000000000000064",
                "atatus.span_id": "c8"
            ])
        )
    }

    func testWritingLogWithOTErrorField() throws {
        let expectation = expectation(description: "Send 3 logs")
        expectation.expectedFulfillmentCount = 3
        core.onEventWriteContext = { _ in expectation.fulfill() }

        // Given
        let integration = TracingWithLoggingIntegration(core: core, service: .mockAny(), networkInfoEnabled: .mockAny())

        // When
        integration.writeLog(
            withSpanContext: .mockAny(),
            fields: [OTLogFields.event: "error"],
            date: .mockAny(),
            else: {}
        )

        integration.writeLog(
            withSpanContext: .mockAny(),
            fields: [OTLogFields.errorKind: "Swift error"],
            date: .mockAny(),
            else: {}
        )

        integration.writeLog(
            withSpanContext: .mockAny(),
            fields: [OTLogFields.event: "error", OTLogFields.errorKind: "Swift error"],
            date: .mockAny(),
            else: {}
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let logs: [LogEvent] = try XCTUnwrap(core.events())
        XCTAssertEqual(logs.count, 3, "It should send 3 logs")
        logs.forEach { log in
            XCTAssertEqual(log.status, .error)
            XCTAssertEqual(log.message, "Span event")
        }
    }

    func testWritingCustomLogWithoutAnyOTFields() throws {
        let expectation = expectation(description: "Send log")
        core.onEventWriteContext = { _ in expectation.fulfill() }

        // Given
        let integration = TracingWithLoggingIntegration(core: core, service: .mockAny(), networkInfoEnabled: .mockAny())

        // When
        integration.writeLog(
            withSpanContext: .mockWith(traceID: .init(idHi: 10, idLo: 100), spanID: 200),
            fields: ["custom field": 123],
            date: .mockDecember15th2019At10AMUTC(),
            else: {}
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let log: LogEvent = try XCTUnwrap(core.events().last, "It should send log")
        XCTAssertEqual(log.date, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(log.status, .info)
        XCTAssertEqual(log.message, "Span event", "It should use default message.")
        ATAssertJSONEqual(
            AnyEncodable(log.attributes.userAttributes),
            AnyEncodable(["custom field": 123])
        )
        ATAssertJSONEqual(
            AnyEncodable(log.attributes.internalAttributes),
            AnyEncodable([
                "atatus.trace_id": "a0000000000000064",
                "atatus.span_id": "c8"
            ])
        )
    }
}
