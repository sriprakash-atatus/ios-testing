/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the licence header.

import XCTest

class SPMProjectUITests: XCTestCase {
    func testDisplayingUI() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.staticTexts["Testing..."].exists)
    }
}
