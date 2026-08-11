/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddRUM` ->
// `AtatusRUM`, `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the `dd` name to `Atatus` in
// comments and docs; rebranded the licence header.

import Foundation
import UIKit

import AtatusCore
import AtatusRUM
import AtatusSessionReplay

import CatalogUIKit

struct SessionReplayScenario: Scenario {
    var initialViewController: UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: CatalogUIKit.bundle)
        return storyboard.instantiateInitialViewController()!
    }

    func instrument(with info: AppInfo) {
        Atatus.initialize(
            with: .benchmark(info: info),
            trackingConsent: .granted
        )

        RUM.enable(
            with: RUM.Configuration(
                applicationID: info.applicationID,
                uiKitViewsPredicate: DefaultUIKitRUMViewsPredicate(),
                uiKitActionsPredicate: DefaultUIKitRUMActionsPredicate()
            )
        )

        SessionReplay.enable(
            with: SessionReplay.Configuration(
                replaySampleRate: 100,
                textAndInputPrivacyLevel: .maskSensitiveInputs,
                imagePrivacyLevel: .maskNone,
                touchPrivacyLevel: .show,
                featureFlags: [.heatmaps: true]
            )
        )

        RUMMonitor.shared().addAttribute(forKey: "scenario", value: "SessionReplay")
    }
}
