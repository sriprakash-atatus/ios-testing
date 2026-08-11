/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; rebranded the licence header.

import XCTest
import AtatusInternal
@testable import AtatusRUM

class SessionReplayDependencyTests: XCTestCase {
    func testWhenSessionReplayIsConfigured_itReadsReplayBeingRecorded() throws {
        let hasReplay: Bool = .random()
        let recordsCountByViewID: [String: Int64] = [.mockRandom(): .mockRandom()]

        // When
        let context: AtatusContext = .mockWith(
            additionalContext: [
                SessionReplayCoreContext.HasReplay(value: hasReplay),
                SessionReplayCoreContext.RecordsCount(value: recordsCountByViewID)
            ]
        )

        // Then
        XCTAssertEqual(context.hasReplay, hasReplay)
        XCTAssertEqual(context.recordsCountByViewID, recordsCountByViewID)
    }

    func testWhenSessionReplayIsNotConfigured_itReadsNoSRBaggage() {
        // When
        let context: AtatusContext = .mockAny()

        // Then
        XCTAssertNil(context.hasReplay)
        XCTAssert(context.recordsCountByViewID.isEmpty)
    }
}
