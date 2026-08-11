/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import XCTest
@testable import AtatusInternal

final class DataFormatTests: XCTestCase {
    func testFormat() throws {
        let format = DataFormat(prefix: "prefix", suffix: "suffix", separator: "\n")
        let events = [
            "abc".data(using: .utf8)!,
            "def".data(using: .utf8)!,
            "ghi".data(using: .utf8)!
        ]
        let formatted = format.format(events)
        let actual = String(data: formatted, encoding: .utf8)!
        let expected =
        """
        prefixabc
        def
        ghisuffix
        """
        XCTAssertEqual(actual, expected)
    }
}
