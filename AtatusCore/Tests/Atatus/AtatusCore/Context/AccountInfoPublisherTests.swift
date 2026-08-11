/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusCore

class AccountInfoPublisherTests: XCTestCase {
    func testNilInitialValue() throws {
        let publisher = AccountInfoPublisher()
        ATAssertReflectionEqual(publisher.initialValue, nil)
    }

    func testPublishAccountInfo() throws {
        let expectation = expectation(description: "account info publisher publishes data")

        // Given
        let publisher = AccountInfoPublisher()
        let accountInfo: AccountInfo = .mockRandom()

        // When
        publisher.publish {
            // Then
            ATAssertReflectionEqual($0, accountInfo)
            expectation.fulfill()
        }

        publisher.current = accountInfo

        // AccountInfoPublisher publishes in sync
        waitForExpectations(timeout: 0)
    }
}
