/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if os(iOS)
import Foundation
import AtatusInternal

internal protocol RecordingController: AnyObject {
    var replaySampleRate: SampleRate { get }
    var textAndInputPrivacy: TextAndInputPrivacyLevel { get }
    var imagePrivacy: ImagePrivacyLevel { get }
    var touchPrivacy: TouchPrivacyLevel { get }

    func startRecording()
    func stopRecording()
}

extension RecordingCoordinator: RecordingController {
}
#endif
