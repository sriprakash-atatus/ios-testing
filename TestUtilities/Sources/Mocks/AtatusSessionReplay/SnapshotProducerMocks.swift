/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)
import Foundation
@_spi(Internal)
@testable import AtatusSessionReplay

// MARK: - `ViewTreeSnapshotProducer` Mocks

public class ViewTreeSnapshotProducerMock: ViewTreeSnapshotProducer {
    public enum TakeSnapshotResult {
        case snapshot(ViewTreeSnapshot)
        case error(Error)
    }

    /// Succeding results for each `takeSnapshot()`.
    var succeedingResults: [TakeSnapshotResult]

    public convenience init(succeedingSnapshots: [ViewTreeSnapshot]) {
        self.init(succeedingResults: succeedingSnapshots.map { .snapshot($0) })
    }

    public convenience init(succeedingErrors: [Error]) {
        self.init(succeedingResults: succeedingErrors.map { .error($0) })
    }

    public init(succeedingResults: [TakeSnapshotResult]) {
        self.succeedingResults = succeedingResults
    }

    @_spi(Internal)
    public func takeSnapshot(with context: Recorder.Context) throws -> ViewTreeSnapshot? {
        guard let result = succeedingResults.isEmpty ? nil : succeedingResults.removeFirst() else {
            return nil
        }
        switch result {
        case .snapshot(let snapshot): return snapshot
        case .error(let error): throw error
        }
    }
}

@_spi(Internal)
public class ViewTreeSnapshotProducerSpy: ViewTreeSnapshotProducer {
    /// Succeeding `context` values passed to `takeSnapshot(with:)`.
    public var succeedingContexts: [Recorder.Context] = []

    public init() {}

    public func takeSnapshot(with context: Recorder.Context) throws -> ViewTreeSnapshot? {
        succeedingContexts.append(context)
        return nil
    }
}

// MARK: - `TouchSnapshotProducer` Mocks

public class TouchSnapshotProducerMock: TouchSnapshotProducer {
    /// Succeding snapshots to return for each `takeSnapshot()`.
    public var succeedingSnapshots: [TouchSnapshot]

    public init(succeedingSnapshots: [TouchSnapshot] = []) {
        self.succeedingSnapshots = succeedingSnapshots
    }

    @_spi(Internal)
    public func takeSnapshot(context: TouchSnapshotContext) -> TouchSnapshot? {
        return succeedingSnapshots.isEmpty ? nil : succeedingSnapshots.removeFirst()
    }
}
#endif
