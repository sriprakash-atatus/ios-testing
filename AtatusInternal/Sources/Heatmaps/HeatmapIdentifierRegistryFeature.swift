/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

internal final class HeatmapIdentifierRegistryFeature: AtatusFeature {
    static var name: String = "heatmap-identifier-registry"

    let messageReceiver: FeatureMessageReceiver = NOPFeatureMessageReceiver()
    let registry: HeatmapIdentifierRegistry

    init(registry: HeatmapIdentifierRegistry) {
        self.registry = registry
    }
}
