/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddRUM` ->
// `AtatusRUM`, `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the licence header.

import UIKit
import AtatusRUM
import AtatusSessionReplay
import AtatusCore

/// Scenario which navigates between multiple views in navigation view controller.
/// - Each view is tracked with RUM and SR.
/// - Each view is presented still for a short moment of time.
/// - Default privacy level is set to `.mask`.
final class SRMultipleViewsRecordingScenario: TestScenario {
    static let storyboardName = "SRMultipleViewsRecordingScenario"

    func configureFeatures() {
        var rumConfig = RUM.Configuration(applicationID: "rum-application-id")
        rumConfig.uiKitViewsPredicate = DefaultUIKitRUMViewsPredicate()
        rumConfig.customEndpoint = Environment.serverMockConfiguration()?.rumEndpoint
        RUM.enable(with: rumConfig)

        var srConfig = SessionReplay.Configuration(replaySampleRate: 100)
        srConfig.touchPrivacyLevel = .show
        srConfig.customEndpoint = Environment.serverMockConfiguration()?.srEndpoint
        SessionReplay.enable(with: srConfig)
    }
}
