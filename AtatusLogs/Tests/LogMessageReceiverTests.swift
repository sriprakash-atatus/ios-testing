/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddLogs`
// -> `AtatusLogs`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusLogs

class LogMessageReceiverTests: XCTestCase {
    func testReceivePartialLogMessage() throws {
        // Given
        let expectation = expectation(description: "Send log")
        let core = PassthroughCoreMock(
            context: .mockWith(service: "service-test"),
            messageReceiver: LogMessageReceiver.mockAny()
        )
        core.onEventWriteContext = { _ in expectation.fulfill() }

        // When
        core.send(
            message: .payload(
                LogMessage(
                    logger: "logger-test",
                    service: nil,
                    date: .mockDecember15th2019At10AMUTC(),
                    message: "message-test",
                    error: nil,
                    level: .info,
                    thread: "thread-test",
                    networkInfoEnabled: nil,
                    userAttributes: nil,
                    internalAttributes: nil
                )
            )
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let log: LogEvent = try XCTUnwrap(core.events().last, "It should send log")
        XCTAssertEqual(log.date, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(log.loggerName, "logger-test")
        XCTAssertEqual(log.serviceName, "service-test")
        XCTAssertEqual(log.threadName, "thread-test")
        XCTAssertEqual(log.message, "message-test")
        XCTAssertEqual(log.status, .info)
        XCTAssertNil(log.error)
        XCTAssertTrue(log.attributes.userAttributes.isEmpty)
        XCTAssertNil(log.attributes.internalAttributes)
        XCTAssertNil(log.networkConnectionInfo)
    }

    func testReceiveCompleteLogMessage() throws {
        // Given
        let expectation = expectation(description: "Send log")
        let core = PassthroughCoreMock(
            context: .mockAny(),
            messageReceiver: LogMessageReceiver.mockAny()
        )
        core.onEventWriteContext = { _ in expectation.fulfill() }

        // When
        core.send(
            message: .payload(
                LogMessage(
                    logger: "logger-test",
                    service: "service-test",
                    date: .mockDecember15th2019At10AMUTC(),
                    message: "message-test",
                    error: .mockAny(),
                    level: .info,
                    thread: "thread-test",
                    networkInfoEnabled: true,
                    userAttributes: ["user": "attribute"],
                    internalAttributes: ["internal": "attribute"]
                )
            )
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let log: LogEvent = try XCTUnwrap(core.events().last, "It should send log")
        XCTAssertEqual(log.date, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(log.loggerName, "logger-test")
        XCTAssertEqual(log.serviceName, "service-test")
        XCTAssertEqual(log.threadName, "thread-test")
        XCTAssertEqual(log.message, "message-test")
        XCTAssertEqual(log.status, .info)
        XCTAssertEqual(log.error?.message, "abc")
        ATAssertJSONEqual(
            AnyEncodable(log.attributes.userAttributes),
            ["user": "attribute"]
        )
        ATAssertJSONEqual(
            AnyEncodable(log.attributes.internalAttributes),
            ["internal": "attribute"]
        )
        XCTAssertNotNil(log.networkConnectionInfo)
    }

    func testReceiveRejectedLogMessage() throws {
        // Given
        let expectation = expectation(description: "Open scope but don't send log")
        let core = PassthroughCoreMock(
            context: .mockWith(service: "service-test"),
            messageReceiver: LogMessageReceiver(
                logEventMapper: SyncLogEventMapper { _ in nil }
            )
        )
        core.onEventWriteContext = { _ in expectation.fulfill() }

        // When
        core.send(
            message: .payload(
                LogMessage(
                    logger: "logger-test",
                    service: nil,
                    date: .mockDecember15th2019At10AMUTC(),
                    message: "message-test",
                    error: nil,
                    level: .info,
                    thread: "thread-test",
                    networkInfoEnabled: nil,
                    userAttributes: nil,
                    internalAttributes: nil
                )
            )
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertTrue(core.events.isEmpty)
    }
}
