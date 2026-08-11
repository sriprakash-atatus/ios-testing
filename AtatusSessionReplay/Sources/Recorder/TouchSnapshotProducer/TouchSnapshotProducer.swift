/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)
import Foundation

internal struct TouchSnapshotContext {
    let touchPrivacy: TouchPrivacyLevel
    let viewServerTimeOffset: TimeInterval?
}

/// Produces `TouchSnapshots` that describe touch interactions.
internal protocol TouchSnapshotProducer {
    /// Produces the snapshot of (touch) interactions that happened since last call to `takeSnapshot()`.
    ///
    /// - Parameter context: context used for sharing common data
    /// - Returns: the snapshot or `nil` if no new touch information is available
    func takeSnapshot(context: TouchSnapshotContext) -> TouchSnapshot?
}
#endif
