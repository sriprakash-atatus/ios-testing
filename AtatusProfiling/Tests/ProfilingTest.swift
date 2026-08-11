/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddMachProfiler` -> `AtatusMachProfiler`, `ddProfiling` -> `AtatusProfiling`; rebranded the
// licence header.

#if !os(watchOS)

import XCTest
import AtatusInternal
import TestUtilities

@testable import AtatusProfiling
import AtatusMachProfiler

class ProfilingTest: XCTestCase {
    func testProfilingConfiguration() throws {
        // Given
        let configuration = Profiling.Configuration(customEndpoint: .mockRandom())
        let core = SingleFeatureCoreMock<ProfilerFeature>()
        XCTAssertEqual(dd_profiler_start(), 1)
        defer { dd_profiler_destroy() }

        // When
        Profiling.enable(with: configuration, in: core)

        // Then
        let feature = core.feature(named: ProfilerFeature.name, type: ProfilerFeature.self)
        let requestBuilder = feature?.requestBuilder as? RequestBuilder
        XCTAssertEqual(feature?.performanceOverride?.maxFileSize, 15.MB.asUInt32())
        XCTAssertEqual(requestBuilder?.customUploadURL, configuration.customEndpoint)
        XCTAssertEqual(feature?.telemetryController.sampleRate, 20)

        let context = try XCTUnwrap(core.context.additionalContext(ofType: ProfilingContext.self))
        XCTAssertEqual(context.status, .running)
    }
}

#endif
