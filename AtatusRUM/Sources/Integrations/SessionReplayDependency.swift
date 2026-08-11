/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

// MARK: - Extracting SR context from `AtatusContext`

extension AtatusContext {
    /// The Session Replay configuration.
    var sessionReplayConfiguration: SessionReplayCoreContext.Configuration? {
        additionalContext(ofType: SessionReplayCoreContext.Configuration.self)
    }

    /// The value indicating if replay is being performed by Session Replay.
    var hasReplay: Bool? {
        additionalContext(ofType: SessionReplayCoreContext.HasReplay.self)?.value
    }

    /// The value of `[String: Int64]` that indicates number of records recorded for a given viewID.
    var recordsCountByViewID: [String: Int64] {
        additionalContext(ofType: SessionReplayCoreContext.RecordsCount.self)?.value ?? [:]
    }
}
