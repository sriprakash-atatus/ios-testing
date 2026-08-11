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

final class FirstFrameReaderTests: XCTestCase {
    func testFirstFrameIsProcessedCorrectly() {
        let dateProvider = DateProviderMock()
        let reader = FirstFrameReader(dateProvider: DateProviderMock(), mediaTimeProvider: MediaTimeProviderMock(current: 0))
        let rumCommandSubscriber = RUMCommandSubscriberMock()
        reader.publish(to: rumCommandSubscriber)
        let frameInfoProvider = FrameInfoProviderMock(target: self, selector: .noOp)

        // 1st frame
        frameInfoProvider.currentFrameTimestamp = 2
        frameInfoProvider.nextFrameTimestamp = 4
        reader.didUpdateFrame(link: frameInfoProvider)

        // 2nd frame (should not be taken into account)
        frameInfoProvider.currentFrameTimestamp = 4
        frameInfoProvider.nextFrameTimestamp = 5
        reader.didUpdateFrame(link: frameInfoProvider)

        XCTAssertEqual(
            rumCommandSubscriber.lastReceivedCommand!.time.timeIntervalSince1970,
            dateProvider.now.addingTimeInterval(1).timeIntervalSince1970,
            accuracy: 1e9
        )
    }
}
