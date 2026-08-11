/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddProfiling` -> `AtatusProfiling`; rebranded
// the licence header.

#if !os(watchOS)

import XCTest
import AtatusProfiling

final class ProfilingConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        // When
        let endpoint: URL = .mockRandom()
        let config = Profiling.Configuration(customEndpoint: endpoint)

        // Then
        XCTAssertEqual(config.customEndpoint, endpoint)
        XCTAssertEqual(config.applicationLaunchSampleRate, 5)
    }
}

#endif
