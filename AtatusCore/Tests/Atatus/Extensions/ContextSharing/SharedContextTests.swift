/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed `dd*` types to `Atatus*`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@_spi(Internal)
@testable import AtatusCore

class SharedContextTests: XCTestCase {
    func testInitializationWithAtatusContext_withNilAccountAndUserInfo_setsNilIds() throws {
        // Given
        let context = AtatusContext.mockWith(userInfo: nil, accountInfo: nil)

        // When
        let sharedContext = SharedContext(atatusContext: context)

        // Then
        XCTAssertNil(sharedContext.userId)
        XCTAssertNil(sharedContext.accountId)
    }

    func testInitializationWithAtatusContext_withCompleteContext() throws {
        // Given
        let context = AtatusContext.mockWith(
            userInfo: UserInfo(
                id: "user-789"
            ),
            accountInfo: AccountInfo(
                id: "account-999"
            )
        )

        // When
        let sharedContext = SharedContext(atatusContext: context)

        // Then
        XCTAssertEqual(sharedContext.userId, "user-789")
        XCTAssertEqual(sharedContext.accountId, "account-999")
    }
}
