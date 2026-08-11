/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if os(iOS)
import Foundation
@preconcurrency import AtatusInternal

/// Immutable inputs needed to build one layer recording.
@available(iOS 13.0, tvOS 13.0, *)
internal struct LayerRecordingContext: Sendable {
    let textAndInputPrivacy: TextAndInputPrivacyLevel
    let imagePrivacy: ImagePrivacyLevel
    let touchPrivacy: TouchPrivacyLevel
    let applicationID: String
    let sessionID: String
    let viewID: String
    let viewServerTimeOffset: TimeInterval?
    let viewPath: String?
    let date: Date
    let telemetry: any Telemetry
}

@available(iOS 13.0, tvOS 13.0, *)
internal protocol LayerRecording {
    /// Schedules a recording from collected screen changes.
    func scheduleRecording(_ changeset: CALayerChangeset, context: LayerRecordingContext) async
}
#endif
