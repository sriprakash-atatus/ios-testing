/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the licence
// header.

@testable import AtatusCore
import XCTest

class CITestIntegrationTests: XCTestCase {
    func testByDefaultCITestIntegrationIsNotConfigured() throws {
        XCTAssertNil(CITestIntegration.active)
    }
}
