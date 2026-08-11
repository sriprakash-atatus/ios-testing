/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)
import Foundation
@testable import AtatusSessionReplay

/// Spies the interaction with `Processing`.
public class SnapshotProcessorSpy: SnapshotProcessing {
    /// An array of snapshots recorded in `process(viewTreeSnapshot:touchSnapshot:)`
    public private(set) var processedSnapshots: [(viewTreeSnapshot: ViewTreeSnapshot, touchSnapshot: TouchSnapshot?)] = []

    public init() {}

    public func process(viewTreeSnapshot: ViewTreeSnapshot, touchSnapshot: TouchSnapshot?) {
        processedSnapshots.append((viewTreeSnapshot, touchSnapshot))
    }
}
#endif
