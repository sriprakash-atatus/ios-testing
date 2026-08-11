/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

extension AtatusCoreProtocol {
    /// Registers a heatmap identifier registry in this core.
    public func register(heatmapIdentifierRegistry: HeatmapIdentifierRegistry) throws {
        guard get(feature: HeatmapIdentifierRegistryFeature.self) == nil else {
            return
        }

        let feature = HeatmapIdentifierRegistryFeature(registry: heatmapIdentifierRegistry)
        try register(feature: feature)
    }

    /// Returns the heatmap identifier registry, if registered.
    public var heatmapIdentifierRegistry: HeatmapIdentifierRegistry? {
        self.get(feature: HeatmapIdentifierRegistryFeature.self)?.registry
    }
}
