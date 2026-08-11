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

/// Publisher that sets Session Replay context for being utilized by other Features.
internal class SRContextPublisher {
    private weak var core: AtatusCoreProtocol?
    private var recordCounts: [String: Int64] = [:]

    init(core: AtatusCoreProtocol) {
        self.core = core
    }

    /// Notifies other Features if Session Replay is recording.
    func setHasReplay(_ value: Bool) {
        core?.set(context: SessionReplayCoreContext.HasReplay(value: value))
    }

    /// Increments the Session Replay record count for a RUM view.
    func incrementRecordCount(by count: Int64, forViewID viewID: String) {
        guard count > 0 else {
            return
        }

        core?.set(
            context: {
                self.recordCounts[viewID, default: 0] += count
                return SessionReplayCoreContext.RecordsCount(value: self.recordCounts)
            }
        )
    }
}
#endif
