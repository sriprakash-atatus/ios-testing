/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; renamed `dd*` members to `at*`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
import OpenTelemetryApi

@testable import AtatusTrace

class OTelSpanIdAtatusTests: XCTestCase {
    func testToAtatus() {
        let otelId = SpanId.random()
        let atId = otelId.toAtatus()
        XCTAssertEqual(otelId.rawValue, atId.rawValue)
    }
}
