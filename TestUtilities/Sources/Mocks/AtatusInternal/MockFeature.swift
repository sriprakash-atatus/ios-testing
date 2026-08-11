/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

internal class MockFeature: AtatusRemoteFeature {
    static var name = "mock-feature"

    var messageReceiver: FeatureMessageReceiver = NOPFeatureMessageReceiver()
    var requestBuilder: FeatureRequestBuilder = MockRequestBuilder()
    var performanceOverride: PerformancePresetOverride?
}

internal class MockRequestBuilder: FeatureRequestBuilder {
    func request(for events: [AtatusInternal.Event], with context: AtatusInternal.AtatusContext, execution: AtatusInternal.ExecutionContext) throws -> URLRequest {
        URLRequest.mockAny()
    }
}
