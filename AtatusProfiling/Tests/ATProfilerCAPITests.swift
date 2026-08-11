/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddMachProfiler` -> `AtatusMachProfiler`;
// renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#if !os(watchOS)
import XCTest
import AtatusMachProfiler

final class ATProfilerCAPITests: XCTestCase {
    private var receivedTraces: [UnsafePointer<stack_trace_t>?] = []
    private var receivedCounts: [Int] = []
    private var callbackUserData: UnsafeMutableRawPointer?

    override func setUp() {
        super.setUp()
        receivedTraces.removeAll()
        receivedCounts.removeAll()
        callbackUserData = nil
    }

    // MARK: - Profiler State Management Tests

    func testProfilerState_initiallyNotRunning() {
        XCTAssertFalse(dd_profiler_is_running(), "Profiler should not be running until started")
    }

    func testProfilerStart_changesStateToRunning() {
        XCTAssertEqual(dd_profiler_start(), 1)
        XCTAssertTrue(dd_profiler_is_running(), "Profiler should be running after start")

        dd_profiler_stop()
        dd_profiler_destroy()
    }

    func testProfilerStop_changesStateToNotRunning() {
        XCTAssertEqual(dd_profiler_start(), 1)
        XCTAssertTrue(dd_profiler_is_running(), "Precondition: profiler should be running")

        dd_profiler_stop()

        XCTAssertFalse(dd_profiler_is_running(), "Profiler should not be running after stop")

        dd_profiler_destroy()
    }

    func testProfilerStartTwice_doesNotCrash() {
        XCTAssertEqual(dd_profiler_start(), 1)

        let secondStartResult = dd_profiler_start()

        XCTAssertEqual(secondStartResult, 1, "Second start while running should succeed (idempotent)")
        XCTAssertTrue(dd_profiler_is_running(), "Profiler should still be running")

        dd_profiler_stop()
        dd_profiler_destroy()
    }

    // MARK: - Memory Management Tests

    func testProfilerDestroy_stopsRunningProfiler() {
        XCTAssertEqual(dd_profiler_start(), 1)
        XCTAssertTrue(dd_profiler_is_running())

        dd_profiler_destroy()

        // Then
        // Should have cleaned up resources without crashing
        // Note: Can't test is_running after destroy as profiler is deallocated
    }
}
#endif // !os(watchOS)
