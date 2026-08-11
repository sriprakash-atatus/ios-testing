/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusCore

class ApplicationStatePublisherTests: XCTestCase {
    func testWhenReceivingAppLifecycleNotification_itUpdatesStatesHistory() throws {
        let date = Date()
        let dateProvider = DateProviderMock(now: date)
        let notificationCenter = NotificationCenter()

        // Given
        let publisher = ApplicationStatePublisher(
            appStateHistory: .mockWith(initialState: .inactive, date: dateProvider.now),
            notificationCenter: notificationCenter,
            dateProvider: dateProvider
        )

        var lastPublishedValue: AppStateHistory?
        publisher.publish { lastPublishedValue = $0 }

        // When / Then
        dateProvider.now += 1
        notificationCenter.post(name: ApplicationNotifications.willEnterForeground, object: nil)
        XCTAssertEqual(lastPublishedValue?.currentState, .inactive)

        dateProvider.now += 1
        notificationCenter.post(name: ApplicationNotifications.didBecomeActive, object: nil)
        XCTAssertEqual(lastPublishedValue?.currentState, .active)

        dateProvider.now += 1
        notificationCenter.post(name: ApplicationNotifications.willResignActive, object: nil)
        XCTAssertEqual(lastPublishedValue?.currentState, .inactive)

        dateProvider.now += 1
        notificationCenter.post(name: ApplicationNotifications.didEnterBackground, object: nil)
        XCTAssertEqual(lastPublishedValue?.currentState, .background)

        let history = try XCTUnwrap(lastPublishedValue)
        XCTAssertEqual(history.state(at: date), .inactive)
        XCTAssertEqual(history.state(at: date + 1), .inactive)
        XCTAssertEqual(history.state(at: date + 2), .active)
        XCTAssertEqual(history.state(at: date + 3), .inactive)
        XCTAssertEqual(history.state(at: date + 4), .background)

        XCTAssertNil(history.state(at: date - 1))
        XCTAssertEqual(history.initialState, .inactive)
        XCTAssertEqual(history.state(at: .distantFuture), .background)
    }
}
