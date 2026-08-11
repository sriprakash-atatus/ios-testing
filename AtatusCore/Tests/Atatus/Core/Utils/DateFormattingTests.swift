/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; rebranded the licence header.

import XCTest
import AtatusInternal
@testable import AtatusCore

class DateFormattingTests: XCTestCase {
    private let date: Date = .mockDecember15th2019At10AMUTC(addingTimeInterval: 0.001)

    func testISO8601DateFormatter() {
        XCTAssertEqual(
            iso8601DateFormatter.string(from: date),
            "2019-12-15T10:00:00.001Z"
        )
    }

    func testPresentationDateFormatter() {
        XCTAssertEqual(
            presentationDateFormatter(withTimeZone: .UTC).string(from: date),
            "10:00:00.001"
        )
        XCTAssertEqual(
            presentationDateFormatter(withTimeZone: .EET).string(from: date),
            "12:00:00.001"
        )
    }
}
