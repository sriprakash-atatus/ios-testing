/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)
import XCTest
@testable import AtatusSessionReplay
@testable import TestUtilities

class QueueTests: XCTestCase {
    func testMainAsyncQueueRunsAsynchronouslyOnTheMainThread() {
        let expectation = self.expectation(description: "Run asynchronously on the main thread")
        let randomValue: Int = .mockRandom()

        // Given
        let queue = MainAsyncQueue()

        // When
        var value = randomValue
        queue.run {
            XCTAssertTrue(Thread.isMainThread)
            value = .mockRandom(otherThan: [randomValue])
            expectation.fulfill()
        }

        // Then
        XCTAssertEqual(value, randomValue)
        waitForExpectations(timeout: 0.5)
        XCTAssertNotEqual(value, randomValue)
    }

    func testBackgroundAsyncQueueRunsAsynchronouslyOnBackgroundThread() {
        let expectation = self.expectation(description: "Run asynchronously on background thread")
        let randomValue: Int = .mockRandom()

        // Given
        let queue = BackgroundAsyncQueue(label: .mockAny())

        // When
        var value = randomValue
        queue.run {
            XCTAssertFalse(Thread.isMainThread)
            value = .mockRandom(otherThan: [randomValue])
            expectation.fulfill()
        }

        // Then
        XCTAssertEqual(value, randomValue)
        waitForExpectations(timeout: 0.5)
        XCTAssertNotEqual(value, randomValue)
    }
}
#endif
