/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Provides heatmap identifiers for UI elements, enabling correlation between RUM actions and Session Replay wireframes.
public protocol HeatmapIdentifierRegistry: Sendable {
    /// Replaces the current identifiers with a new snapshot.
    func setHeatmapIdentifiers(_ heatmapIdentifiers: [ObjectIdentifier: HeatmapIdentifier])

    /// Returns the heatmap identifier for a UI element, if available.
    func heatmapIdentifier(for objectIdentifier: ObjectIdentifier) -> HeatmapIdentifier?
}
