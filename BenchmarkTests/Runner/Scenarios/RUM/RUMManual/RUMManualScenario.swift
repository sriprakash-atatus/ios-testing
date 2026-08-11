/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddRUM` ->
// `AtatusRUM`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import SwiftUI

import AtatusCore
import AtatusRUM

struct RUMManualScenario: Scenario {
    var initialViewController: UIViewController {
        UIHostingController(rootView: RUMManualContentView())
    }

    func instrument(with info: AppInfo) {
        Atatus.initialize(
            with: .benchmark(info: info),
            trackingConsent: .granted
        )

        RUM.enable(
            with: RUM.Configuration(applicationID: info.applicationID)
        )

        RUMMonitor.shared().addAttribute(forKey: "scenario", value: "RUMManual")
    }
}
