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

/// A type writing Session Replay records to `AtatusCore`.
internal protocol RecordWriting {
    /// Writes next records to SDK core.
    func write(nextRecord: EnrichedRecord)
}

internal class RecordWriter: RecordWriting {
    /// An instance of SDK core the SR feature is registered to.
    private weak var core: AtatusCoreProtocol?

    init(core: AtatusCoreProtocol) {
        self.core = core
    }

    // MARK: - Writing

    func write(nextRecord: EnrichedRecord) {
        core?.scope(for: SessionReplayFeature.self).eventWriteContext { _, recordWriter in
            recordWriter.write(value: nextRecord)
        }
    }
}
#endif
