/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCrashReporting` -> `AtatusCrashReporting`,
// `ddInternal` -> `AtatusInternal`; renamed `dd*` types to `Atatus*`; rebranded the licence
// header.

import XCTest
import TestUtilities
import AtatusCrashReporting
@testable import AtatusInternal

/// Tests integration of `AtatusCore` and `AtatusCrashReporting` for backtrace generation.
class GeneratingBacktraceTests: XCTestCase {
    private var core: AtatusCoreProxy! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        core = AtatusCoreProxy(context: .mockWith(trackingConsent: .granted))
    }

    override func tearDownWithError() throws {
        try core.flushAndTearDown()
        core = nil
        super.tearDown()
    }

    func testGeneratingBacktraceOfTheCurrentThread() throws {
        #if os(watchOS)
        throw XCTSkip("Backtrace generation is not supported on watchOS")
        #endif
        // Given
        CrashReporting.enable(in: core)
        XCTAssertNotNil(core.get(feature: BacktraceReportingFeature.self), "`BacktraceReportingFeature` must be registered")

        // When
        let backtrace = try XCTUnwrap(core.backtraceReporter.generateBacktrace())

        // Then
        XCTAssertGreaterThan(backtrace.threads.count, 0, "Some thread(s) should be recorded")
        XCTAssertGreaterThan(backtrace.binaryImages.count, 0, "Some binary image(s) should be recorded")
        XCTAssertFalse(backtrace.threads.contains(where: { $0.crashed }), "No thread should be marked as crashed")

        XCTAssertTrue(
            backtrace.stack.contains("AtatusIntegrationTests"),
            "Backtrace stack should include at least one frame from `AtatusCoreTests` image"
        )
        XCTAssertTrue(
            backtrace.stack.contains("XCTest"),
            "Backtrace stack should include at least one frame from `XCTest` image"
        )
        XCTAssertTrue(
            backtrace.binaryImages.contains(where: { $0.libraryName == "AtatusIntegrationTests" }),
            "Backtrace should include the image for `AtatusCoreTests`"
        )
        XCTAssertTrue(
            // Assert on prefix as it is `XCTestCore` on iOS 15+ and `XCTest` earlier:
            backtrace.binaryImages.contains(where: { $0.libraryName.hasPrefix("XCTest") }),
            "Backtrace should include the image for `XCTest`"
        )
    }

    func testGeneratingBacktraceOfTheMainThread() throws {
        #if os(watchOS)
        throw XCTSkip("Backtrace generation is not supported on watchOS")
        #endif
        // Given
        CrashReporting.enable(in: core)

        // When
        XCTAssertTrue(Thread.current.isMainThread)
        let threadID = Thread.currentThreadID
        let backtrace = try XCTUnwrap(core.backtraceReporter.generateBacktrace(threadID: threadID))

        // Then
        XCTAssertFalse(backtrace.stack.isEmpty)
        XCTAssertTrue(backtrace.stack.contains("XCTestCore"), "Main thread stack should include XCTestCore symbols")
    }

    func testGeneratingBacktraceOfSecondaryThread() throws {
        #if os(watchOS)
        throw XCTSkip("Backtrace generation is not supported on watchOS")
        #endif
        // Given
        CrashReporting.enable(in: core)

        // When
        let semaphore = DispatchSemaphore(value: 0)
        var threadID: ThreadID?

        let thread = Thread {
            XCTAssertFalse(Thread.current.isMainThread)
            threadID = Thread.currentThreadID
            semaphore.signal()
            Thread.sleep(forTimeInterval: 1)
        }

        thread.start()
        XCTAssertEqual(semaphore.wait(timeout: .now() + 5), .success)
        thread.cancel()

        let backtrace = try XCTUnwrap(core.backtraceReporter.generateBacktrace(threadID: threadID!))

        // Then
        XCTAssertFalse(backtrace.stack.isEmpty)
        XCTAssertFalse(backtrace.stack.contains("UIKit"), "Secondary thread stack should NOT include UIKit symbols")
    }
}
