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

class CrossPlatformExtensionTests: XCTestCase {
    func testSubscribe_receivesContextUpdates() throws {
        // Given
        let core = AtatusCoreProxy()
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        @ReadWriteLock
        var lastContext: SharedContext?
        CrossPlatformExtension.subscribe { context in
            lastContext = context
        }

        // When
        core.setUserInfo(id: "user-123")
        core.setAccountInfo(id: "account-456")
        try core.flushAndTearDown()

        // Then
        // Verify we eventually get the user and account info
        XCTAssertEqual(lastContext?.userId, "user-123", "Should have user ID in final context")
        XCTAssertEqual(lastContext?.accountId, "account-456", "Should have account ID in final context")
    }
}
