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

class OTelTraceIdAtatusTests: XCTestCase {
    func testToAtatus_onlyHigherOrderBitsAreConsidered() {
        let otelId = TraceId.random()
        let atId = otelId.toAtatus()
        XCTAssertEqual(otelId.idLo, atId.idLo)
        XCTAssertEqual(otelId.idHi, atId.idHi)
    }
}
