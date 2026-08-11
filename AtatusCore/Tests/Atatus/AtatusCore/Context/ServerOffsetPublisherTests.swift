/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`;
// rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusCore

class ServerOffsetPublisherTests: XCTestCase {
    func testPickRandomAtatusNTPServers() throws {
        let kronos = KronosClockMock()
        let provider = AtatusNTPDateProvider(kronos: kronos)
        let publisher = ServerOffsetPublisher(provider: provider)

        var pools: Set<String> = []

        try (0..<100).forEach { _ in
            publisher.publish { _ in }
            let pool = try XCTUnwrap(kronos.currentPool)
            XCTAssertTrue(pool.hasSuffix(".atatus.pool.ntp.org"))
            pools.insert(pool)
        }

        XCTAssertEqual(pools, Set(AtatusNTPServers), "Each time Atatus NTP server should be picked randomly.")
    }

    func testWhenSyncSucceedsOnce_itPublishesOffset() throws {
        let expectation = expectation(description: "kronos publisher publishes offset")

        // Given
        let kronos = KronosClockMock()
        let provider = AtatusNTPDateProvider(kronos: kronos)
        let publisher = ServerOffsetPublisher(provider: provider)

        // When
        publisher.publish {
            // Then
            XCTAssertEqual($0, -1)
            expectation.fulfill()
        }

        kronos.update(offset: -1)

        // KronosClockMock publishes in sync
        waitForExpectations(timeout: 0)
    }

    func testWhenSyncCompletesSuccessfully_itPublishesOffset() throws {
        let dd = AT.mockWith(logger: CoreLoggerMock())
        defer { dd.reset() }

        let expectation = expectation(description: "kronos publisher publishes offset")
        expectation.expectedFulfillmentCount = 2

        // Given
        let kronos = KronosClockMock()
        let provider = AtatusNTPDateProvider(kronos: kronos)
        let publisher = ServerOffsetPublisher(provider: provider)

        // When
        publisher.publish {
            // Then
            XCTAssertEqual($0, -1)
            expectation.fulfill()
        }

        kronos.update(offset: -1)
        kronos.complete()

        // Then
        XCTAssertEqual(
            dd.logger.debugLog?.message,
            """
            NTP time synchronization completed.
            Server time will be used for signing events (-1.0s difference with device time).
            """
        )

        // KronosClockMock publishes in sync
        waitForExpectations(timeout: 0)
    }

    func testWhenSyncFails_itPublishesZero() throws {
        let dd = AT.mockWith(logger: CoreLoggerMock())
        defer { dd.reset() }

        let expectation = expectation(description: "kronos publisher publishes 0")

        // Given
        let kronos = KronosClockMock()
        let provider = AtatusNTPDateProvider(kronos: kronos)
        let publisher = ServerOffsetPublisher(provider: provider)

        // When
        publisher.publish {
            // Then
            XCTAssertEqual($0, .zero)
            expectation.fulfill()
        }

        kronos.complete()

        // Then
        XCTAssertEqual(
            dd.logger.errorLog?.message,
            """
            NTP time synchronization failed.
            Device time will be used for signing events.
            """
        )

        // KronosClockMock publishes in sync
        waitForExpectations(timeout: 0)
    }
}
