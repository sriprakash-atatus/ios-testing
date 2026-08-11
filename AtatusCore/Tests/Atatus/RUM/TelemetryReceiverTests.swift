/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusRUM

class TelemetryReceiverTests: XCTestCase {
    // MARK: - Thread safety

    func testSendTelemetryAndReset_onAnyThread() throws {
        let core = AtatusCoreProxy(
            context: .mockWith(
                version: .mockRandom(),
                source: .mockAnySource(),
                sdkVersion: .mockRandom()
            )
        )
        defer { XCTAssertNoThrow(try core.flushAndTearDown()) }

        RUM.enable(with: .mockAny(), in: core)

        // swiftlint:disable opening_brace
        callConcurrently(
            closures: [
                { core.telemetry.debug(id: .mockRandom(), message: "telemetry debug") },
                { core.telemetry.error(id: .mockRandom(), message: "telemetry error", kind: "error.kind", stack: "error.stack") },
                { core.telemetry.configuration(batchSize: .mockRandom()) },
                { core.set(context: RUMCoreContext.mockRandom()) }
            ],
            iterations: 50
        )
        // swiftlint:enable opening_brace
    }
}
