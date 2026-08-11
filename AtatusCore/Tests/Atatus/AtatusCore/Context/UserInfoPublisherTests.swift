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

class UserInfoPublisherTests: XCTestCase {
    func testEmptyInitialValue() throws {
        let publisher = UserInfoPublisher()
        ATAssertReflectionEqual(publisher.initialValue, .empty)
    }

    func testPublishUserInfo() throws {
        let expectation = expectation(description: "user info publisher publishes data")

        // Given
        let publisher = UserInfoPublisher()
        let userInfo: UserInfo = .mockRandom()

        // When
        publisher.publish {
            // Then
            ATAssertReflectionEqual($0, userInfo)
            expectation.fulfill()
        }

        publisher.current = userInfo

        // UserInfoPublisher publishes in sync
        waitForExpectations(timeout: 0)
    }
}
