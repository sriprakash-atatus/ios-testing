/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddLogs` ->
// `AtatusLogs`, `ddRUM` -> `AtatusRUM`, `ddSessionReplay` -> `AtatusSessionReplay`,
// `ddTrace` -> `AtatusTrace`; rebranded the licence header.

import XCTest
@testable import AtatusCore
@testable import AtatusRUM
@testable import AtatusLogs
@testable import AtatusTrace
#if os(iOS)
@testable import AtatusSessionReplay
#endif

class CoreMetricsIntegrationTests: XCTestCase {
    func testResolvingTrackValueFromFeatureName() {
        XCTAssertEqual(BatchMetric.trackValue(for: RUMFeature.name), "rum")
        XCTAssertEqual(BatchMetric.trackValue(for: TraceFeature.name), "trace")
        XCTAssertEqual(BatchMetric.trackValue(for: LogsFeature.name), "logs")
#if os(iOS)
        XCTAssertEqual(BatchMetric.trackValue(for: SessionReplayFeature.name), "sr")
        XCTAssertEqual(BatchMetric.trackValue(for: ResourcesFeature.name), "sr-resources")
#endif
    }
}
