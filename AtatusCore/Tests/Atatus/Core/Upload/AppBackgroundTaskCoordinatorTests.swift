/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; rebranded the licence header.

#if !os(watchOS)

import XCTest
import AtatusInternal
@testable import AtatusCore

class AppBackgroundTaskCoordinatorTests: XCTestCase {
    var appSpy: AppSpy?
    var coordinator: AppBackgroundTaskCoordinator?

    override func setUp() {
        super.setUp()
        appSpy = AppSpy()
        coordinator = AppBackgroundTaskCoordinator(
            app: appSpy
        )
    }

    func testBeginBackgroundTask() {
        coordinator?.beginBackgroundTask()

        XCTAssertEqual(appSpy?.beginBackgroundTaskCalled, true)
        XCTAssertEqual(appSpy?.endBackgroundTaskCalled, false)
    }

    func testEndBackgroundTask() throws {
        coordinator?.beginBackgroundTask()
        coordinator?.endBackgroundTask()

        XCTAssertEqual(appSpy?.beginBackgroundTaskCalled, true)
        XCTAssertEqual(appSpy?.endBackgroundTaskCalled, true)
    }

    func testEndBackgroundTaskNotCalledWhenNotBegan() throws {
        coordinator?.endBackgroundTask()

        XCTAssertEqual(appSpy?.beginBackgroundTaskCalled, false)
        XCTAssertEqual(appSpy?.endBackgroundTaskCalled, false)
    }

    func testBeginEndsPreviousTask() throws {
        coordinator?.beginBackgroundTask()
        coordinator?.beginBackgroundTask()

        XCTAssertEqual(appSpy?.beginBackgroundTaskCalled, true)
        XCTAssertEqual(appSpy?.endBackgroundTaskCalled, true)
    }
}

class AppSpy: UIKitAppBackgroundTaskCoordinator {
    var beginBackgroundTaskCalled = false
    var endBackgroundTaskCalled = false

    var handler: (() -> Void)? = nil

    func beginBgTask(_ handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        self.handler = handler
        beginBackgroundTaskCalled = true
        return UIBackgroundTaskIdentifier(rawValue: 1)
    }

    func endBgTask(_ identifier: UIBackgroundTaskIdentifier) {
        endBackgroundTaskCalled = true
    }
}

#endif
