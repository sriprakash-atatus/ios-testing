/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

#if os(iOS)
import Foundation
import AtatusInternal

internal class ResourcesFeature: AtatusRemoteFeature {
    static var name = "session-replay-resources"

    let messageReceiver: FeatureMessageReceiver = NOPFeatureMessageReceiver()
    let performanceOverride: PerformancePresetOverride?

    let requestBuilder: FeatureRequestBuilder

    init(
        core: AtatusCoreProtocol,
        configuration: SessionReplay.Configuration
    ) {
        self.requestBuilder = ResourceRequestBuilder(
            customUploadURL: configuration.customEndpoint,
            telemetry: core.telemetry
        )
        self.performanceOverride = PerformancePresetOverride(
            maxFileSize: SessionReplay.maxObjectSize,
            maxObjectSize: SessionReplay.maxObjectSize
        )
    }
}
#endif
