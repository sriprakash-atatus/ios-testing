/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; rebranded the licence
// header.

import XCTest
import AtatusRUM

class RUMConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        // When
        let config = RUM.Configuration(applicationID: "app-id")

        // Then
        XCTAssertEqual(config.applicationID, "app-id")
        XCTAssertEqual(config.sessionSampleRate, 100)
        XCTAssertEqual(config.telemetrySampleRate, 20)
        #if !os(watchOS)
        XCTAssertNil(config.uiKitViewsPredicate)
        XCTAssertNil(config.uiKitActionsPredicate)
        XCTAssertNil(config.swiftUIViewsPredicate)
        XCTAssertNil(config.swiftUIActionsPredicate)
        XCTAssertTrue(config.trackMemoryWarnings)
        #endif
        XCTAssertNil(config.urlSessionTracking)
        XCTAssertTrue(config.trackFrustrations)
        XCTAssertFalse(config.trackBackgroundEvents)
        XCTAssertEqual(config.longTaskThreshold, 0.1)
        XCTAssertNil(config.appHangThreshold)
        XCTAssertEqual(config.vitalsUpdateFrequency, .average)
        XCTAssertNil(config.viewEventMapper)
        XCTAssertNil(config.resourceEventMapper)
        XCTAssertNil(config.actionEventMapper)
        XCTAssertNil(config.errorEventMapper)
        XCTAssertNil(config.longTaskEventMapper)
        XCTAssertNil(config.onSessionStart)
        XCTAssertNil(config.customEndpoint)
        XCTAssertTrue(config.trackAnonymousUser)
        XCTAssertTrue(config.featureFlags[.trackScrollAndSwipeActions])
    }
}
