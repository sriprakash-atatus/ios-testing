/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusCore

class JSONEncoderTests: XCTestCase {
    private let jsonEncoder = JSONEncoder.dd.default()

    func testDateEncoding() throws {
        let encodedDate = try jsonEncoder.encode(
            EncodingContainer(Date.mockDecember15th2019At10AMUTC(addingTimeInterval: 0.123))
        )

        XCTAssertEqual(encodedDate.utf8String, #"{"value":"2019-12-15T10:00:00.123Z"}"#)
    }

    func testURLEncoding() throws {
        let encodedURL = try jsonEncoder.encode(
            EncodingContainer(URL(string: "https://example.com/foo")!)
        )

        if #available(iOS 13.0, OSX 10.15, *) {
            XCTAssertEqual(encodedURL.utf8String, #"{"value":"https://example.com/foo"}"#)
        } else {
            XCTAssertEqual(encodedURL.utf8String, #"{"value":"https:\/\/example.com\/foo"}"#)
        }
    }
}
