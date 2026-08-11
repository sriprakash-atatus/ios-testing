/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

internal struct FlagsEvaluationFeature: AtatusRemoteFeature {
    static let name = "flags-evaluation"

    let requestBuilder: any FeatureRequestBuilder
    let messageReceiver: any FeatureMessageReceiver
    let performanceOverride: PerformancePresetOverride?

    init(
        customIntakeURL: URL?,
        telemetry: Telemetry
    ) {
        requestBuilder = EvaluationRequestBuilder(
            customIntakeURL: customIntakeURL,
            telemetry: telemetry
        )
        messageReceiver = NOPFeatureMessageReceiver()
        performanceOverride = PerformancePresetOverride(maxObjectsInFile: 50)
    }
}
