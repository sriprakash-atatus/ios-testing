/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; rebranded the licence
// header.

import XCTest
import TestUtilities
@testable import AtatusRUM

// TODO: RUMM-2034 Remove this flag once we have a host application for tests
#if os(iOS)

class UIApplicationSwizzlerTests: XCTestCase {
    private let handler = RUMActionsHandlerMock()
    private lazy var swizzler = try! UIApplicationSwizzler(handler: handler)

    override func setUp() {
        super.setUp()
        swizzler.swizzle()
    }

    override func tearDown() {
        swizzler.unswizzle()
        super.tearDown()
    }

    func testWhenSendEventIsCalled_itNotifiesTheHandler() {
        let expectation = self.expectation(description: "Notify handler")

        let anyApplication = UIApplication.shared
        let anyEvent = UIEvent()

        handler.onSendEvent = { application, event in
            XCTAssertTrue(application === anyApplication)
            XCTAssertTrue(event === anyEvent)
            expectation.fulfill()
        }

        anyApplication.sendEvent(anyEvent)

        waitForExpectations(timeout: 1.5, handler: nil)
    }
}

#endif
