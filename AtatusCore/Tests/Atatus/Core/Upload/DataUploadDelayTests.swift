/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the licence
// header.

import XCTest
import TestUtilities

@testable import AtatusCore

class DataUploadDelayTests: XCTestCase {
    private let mockPerformance = UploadPerformanceMock(
        initialUploadDelay: 3,
        minUploadDelay: 1,
        maxUploadDelay: 20,
        uploadDelayChangeRate: 0.1,
        maxBatchesPerUpload: .mockAny()
    )

    func testWhenNotModified_itReturnsInitialDelay() {
        let delay = DataUploadDelay(performance: mockPerformance)
        XCTAssertEqual(delay.current, mockPerformance.initialUploadDelay)
        XCTAssertEqual(delay.current, mockPerformance.initialUploadDelay)
    }

    func testWhenReset_itGoesDownToMinimumDelay() {
        let delay = DataUploadDelay(performance: mockPerformance)
        delay.increase()
        delay.reset()
        XCTAssertEqual(delay.current, mockPerformance.minUploadDelay)
    }

    func testWhenIncreasing_itClampsToMaximumDelay() {
        let delay = DataUploadDelay(performance: mockPerformance)
        var previousValue: TimeInterval = delay.current

        while previousValue < mockPerformance.maxUploadDelay {
            delay.increase()

            let nextValue = delay.current
            XCTAssertEqual(
                nextValue / previousValue,
                1.0 + mockPerformance.uploadDelayChangeRate,
                accuracy: 0.1
            )
            XCTAssertGreaterThanOrEqual(nextValue, min(previousValue, mockPerformance.maxUploadDelay))
            previousValue = nextValue
        }
    }
}
