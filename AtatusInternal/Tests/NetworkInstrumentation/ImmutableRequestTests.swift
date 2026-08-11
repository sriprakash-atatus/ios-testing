/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed `dd*`
// members to `at*`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

class ImmutableRequestTests: XCTestCase {
    func testReadingURL() {
        let original: URLRequest = .mockWith(url: "https://example.com")
        let immutable = ImmutableRequest(request: original)
        XCTAssertEqual(immutable.url, original.url)
    }

    func testReadingHTTPMethod() {
        let original: URLRequest = .mockWith(httpMethod: .mockRandom())
        let immutable = ImmutableRequest(request: original)
        XCTAssertEqual(immutable.httpMethod, original.httpMethod)
    }

    func testReadingAtatusOriginHeader() {
        let expectedValue: String = .mockRandom(length: 128)
        let original: URLRequest = .mockWith(
            headers: [
                TracingHTTPHeaders.originField: expectedValue
            ]
        )
        let immutable = ImmutableRequest(request: original)
        XCTAssertEqual(immutable.atOriginHeaderValue, expectedValue)
    }

    func testPreservingUnsafeOriginal() {
        let original: URLRequest = .mockAny()
        let immutable = ImmutableRequest(request: original)
        XCTAssertEqual(immutable.unsafeOriginal, original)
    }
}
