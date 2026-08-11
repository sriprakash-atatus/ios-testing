/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if !os(watchOS)
import Foundation
import AtatusInternal

internal final class HeatmapIdentifierStore: @unchecked Sendable, HeatmapIdentifierRegistry {
    @ReadWriteLock
    private var identifiers: [ObjectIdentifier: HeatmapIdentifier] = [:]

    func setHeatmapIdentifiers(_ heatmapIdentifiers: [ObjectIdentifier: HeatmapIdentifier]) {
        identifiers = heatmapIdentifiers
    }

    func heatmapIdentifier(for objectIdentifier: ObjectIdentifier) -> HeatmapIdentifier? {
        identifiers[objectIdentifier]
    }
}
#endif
