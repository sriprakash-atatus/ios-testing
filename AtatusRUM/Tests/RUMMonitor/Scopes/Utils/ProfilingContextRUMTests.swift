/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`; rebranded the
// licence header.

import XCTest
import AtatusInternal
@testable import AtatusRUM

final class ProfilingContextRUMTests: XCTestCase {
    func testDDProfiling_mapsRunningStatus() {
        let profiling = ProfilingContext(status: .running).atProfiling

        XCTAssertEqual(profiling.status, .running)
        XCTAssertNil(profiling.errorReason)
        XCTAssertNil(profiling.quotaReason)
    }

    func testDDProfiling_mapsStoppedStatus() throws {
        let stopReasons: [ProfilingContext.Status.StopReason] = [.manual, .notStarted, .timeout, .prewarmed]
        let quotaReasons: [ATProfiling.QuotaReason] = [
            .quotaOk, .quotaExceeded, .orgDisabled, .backendUnavailable, .undefined, .timeout, .apiError
        ]

        let quotaReason = try XCTUnwrap(quotaReasons.randomElement())
        let stoppedProfiling = ProfilingContext(
            status: .stopped(reason: try XCTUnwrap(stopReasons.randomElement())),
            quotaReason: quotaReason
        ).atProfiling

        XCTAssertEqual(stoppedProfiling.status, .stopped)
        XCTAssertNil(stoppedProfiling.errorReason)
        XCTAssertEqual(stoppedProfiling.quotaReason, quotaReason)
    }

    func testDDProfiling_mapsErrorStatus() {
        let memoryAllocationFailure = ProfilingContext(status: .error(reason: .memoryAllocationFailed)).atProfiling

        XCTAssertEqual(memoryAllocationFailure.status, .error)
        XCTAssertEqual(memoryAllocationFailure.errorReason, .unexpectedException)
        XCTAssertNil(memoryAllocationFailure.quotaReason)

        let alreadyStarted = ProfilingContext(status: .error(reason: .alreadyStarted)).atProfiling

        XCTAssertEqual(alreadyStarted.status, .error)
        XCTAssertNil(alreadyStarted.errorReason)
        XCTAssertNil(alreadyStarted.quotaReason)

        let unknown = ProfilingContext(status: .unknown).atProfiling

        XCTAssertEqual(unknown.status, .error)
        XCTAssertNil(unknown.errorReason)
        XCTAssertNil(unknown.quotaReason)
    }
}
