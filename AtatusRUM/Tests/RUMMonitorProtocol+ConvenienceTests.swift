/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusRUM

class RUMMonitorProtocol_ConvenienceTests: XCTestCase {
    /// Sanity check if calling methods from `RUMMonitorProtocol+Convenience.swift` doesn't cause
    /// infinite loop and crash.
    ///
    /// TODO: RUMM-3347 Remove this test once protocol extension methods are safe by desing
    func testCallingExtensionMethodsIsSafe() {
        // Given
        let monitor = Monitor(
            dependencies: .mockAny(),
            dateProvider: SystemDateProvider()
        )

        // When & Then (no crash)
        #if !os(watchOS)
        monitor.startView(viewController: mockView)
        monitor.stopView(viewController: mockView)
        #endif
        monitor.startView(key: "view-key")
        monitor.stopView(key: "view-key")
        monitor.addError(message: .mockAny())
        monitor.addError(error: ProgrammerError(description: .mockAny()))
        monitor.startResource(resourceKey: .mockAny(), request: .mockAny())
        monitor.startResource(resourceKey: .mockAny(), url: .mockRandom())
        monitor.startResource(resourceKey: .mockAny(), httpMethod: .mockAny(), urlString: .mockAny())
        monitor.addResourceMetrics(resourceKey: .mockAny(), metrics: .mockAny())
        monitor.stopResource(resourceKey: .mockAny(), response: .mockAny())
        monitor.stopResource(resourceKey: .mockAny(), kind: .mockAny())
        monitor.stopResourceWithError(resourceKey: .mockAny(), error: ProgrammerError(description: .mockAny()))
        monitor.stopResourceWithError(resourceKey: .mockAny(), message: .mockAny())
        monitor.addAction(type: .click, name: .mockAny())
        monitor.startAction(type: .click, name: .mockAny())
        monitor.stopAction(type: .click)
        monitor.startOperation(name: .mockAny())
        monitor.succeedOperation(name: .mockAny())
        monitor.failOperation(name: .mockAny(), reason: .mockAny())
    }
}
