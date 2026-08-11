/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@_spi(objc)
@testable import AtatusTrace

class ATTraceTests: XCTestCase {
    private var core: FeatureRegistrationCoreMock! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        core = FeatureRegistrationCoreMock()
        CoreRegistry.register(default: core)
    }

    override func tearDown() {
        CoreRegistry.unregisterDefault()
        core = nil
        super.tearDown()
    }

    func testWhenNotEnabled() {
        XCTAssertTrue(objc_Tracer.shared().dd?.swiftTracer is ATNoopTracer)
    }

    func testWhenEnabled() {
        objc_Trace.enable(with: objc_TraceConfiguration())
        XCTAssertTrue(objc_Tracer.shared().dd?.swiftTracer is AtatusTracer)
    }
}
