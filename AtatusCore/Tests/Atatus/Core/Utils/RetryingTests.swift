/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the licence
// header.

import XCTest
import TestUtilities
@testable import AtatusCore

private class OperationMock {
    private let succeedingCallResults: [Result<Int, Error>]
    private(set) var callsReceived = 0

    init(_ succeedingCallResults: [Result<Int, Error>]) {
        self.succeedingCallResults = succeedingCallResults
    }

    func operation() throws -> Int {
        let result = succeedingCallResults[callsReceived]
        callsReceived += 1
        return try result.get()
    }
}

class RetryingTests: XCTestCase {
    func testWhenBlockSucceedsRightAway() throws {
        let randomValue: Int = .random(in: 0..<100)

        // When
        let mock = OperationMock([.success(randomValue)])
        let result = try retry(times: 3, delay: 0.001, block: mock.operation)

        // Then
        XCTAssertEqual(mock.callsReceived, 1)
        XCTAssertEqual(result, randomValue)
    }

    func testWhenBlockSucceedsInFirstRetry() throws {
        let randomValue: Int = .random(in: 0..<100)

        // When
        let mock = OperationMock([.failure(ErrorMock()), .success(randomValue)])
        let result = try retry(times: 3, delay: 0.001, block: mock.operation)

        // Then
        XCTAssertEqual(mock.callsReceived, 2)
        XCTAssertEqual(result, randomValue)
    }

    func testWhenBlockSucceedsInLastRetry() throws {
        let randomValue: Int = .random(in: 0..<100)

        // When
        let mock = OperationMock([.failure(ErrorMock()), .failure(ErrorMock()), .success(randomValue)])
        let result = try retry(times: 3, delay: 0.001, block: mock.operation)

        // Then
        XCTAssertEqual(mock.callsReceived, 3)
        XCTAssertEqual(result, randomValue)
    }

    func testWhenBlockDoesNotSucceedInRetry() throws {
        let anyError = ErrorMock(.mockAny())
        let lastError = ErrorMock(.mockRandom())

        // When
        let mock = OperationMock([.failure(anyError), .failure(anyError), .failure(lastError)])
        XCTAssertThrowsError(try retry(times: 3, delay: 0.001, block: mock.operation)) { error in
            XCTAssertEqual((error as? ErrorMock)?.description, lastError.description)
        }

        // Then
        XCTAssertEqual(mock.callsReceived, 3)
    }
}
