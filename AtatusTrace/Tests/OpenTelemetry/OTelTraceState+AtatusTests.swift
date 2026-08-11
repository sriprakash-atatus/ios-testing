/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
import OpenTelemetryApi

@testable import AtatusTrace

final class OTelTraceStateAtatusTests: XCTestCase {
    func testW3C_givenEmptyEntries() throws {
        let traceState = TraceState(entries: [])!
        XCTAssertEqual("", traceState.w3c())
    }

    func testW3C_givenSomeEntries() throws {
        let traceState = TraceState(
            entries: [
                .init(key: "foo", value: "bar")!,
                .init(key: "bar", value: "baz")!
            ]
        )!

        XCTAssertEqual("foo=bar,bar=baz", traceState.w3c())
    }
}
