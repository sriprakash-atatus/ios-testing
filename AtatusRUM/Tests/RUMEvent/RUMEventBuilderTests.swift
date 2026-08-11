/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusRUM

class RUMEventBuilderTests: XCTestCase {
    func testGivenEventBuilderWithEventMapper_whenEventIsModified_itBuildsModifiedEvent() throws {
        let builder = RUMEventBuilder(
            eventsMapper: .mockWith(
                viewEventMapper: { _ in .mockRandom() }
            )
        )
        let originalEventModel = RUMViewEvent.mockRandom()
        let event = try XCTUnwrap(
            builder.build(from: originalEventModel)
        )

        ATAssertReflectionNotEqual(event, originalEventModel)
    }

    func testGivenEventBuilderWithEventMapper_whenEventIsDropped_itBuildsNoEvent() {
        let builder = RUMEventBuilder(
            eventsMapper: .mockWith(
                resourceEventMapper: { _ in nil }
            )
        )
        let event = builder.build(from: RUMResourceEvent.mockRandom())
        XCTAssertNil(event)
    }

    func testGivenEventBuilderWithNoEventMapper_whenBuildingAnEvent_itBuildsEventWithOriginalModel() throws {
        let builder = RUMEventBuilder(
            eventsMapper: .mockWith(
                resourceEventMapper: { $0 }
            )
        )
        let originalEventModel = RUMResourceEvent.mockRandom()
        let event = try XCTUnwrap(
            builder.build(from: originalEventModel)
        )
        ATAssertReflectionEqual(event, originalEventModel)
    }
}
