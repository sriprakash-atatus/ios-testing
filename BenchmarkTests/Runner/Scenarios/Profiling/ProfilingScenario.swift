/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddProfiling` ->
// `AtatusProfiling`, `ddRUM` -> `AtatusRUM`; rebranded the `dd` name to `Atatus` in comments and
// docs; rebranded the licence header.

import Foundation
import SwiftUI

import AtatusCore
import AtatusRUM
import AtatusProfiling

struct ProfilingScenario: Scenario {
    var initialViewController: UIViewController {
        UIHostingController(rootView: ProfilingContentView())
    }

    func instrument(with info: AppInfo) {
        Atatus.initialize(
            with: .benchmark(info: info),
            trackingConsent: .granted
        )

        RUM.enable(
            with: RUM.Configuration(
                applicationID: info.applicationID,
                longTaskThreshold: 0.1,
                appHangThreshold: 0.4
            )
        )

        RUMMonitor.shared().addAttribute(forKey: "scenario", value: "ContinuousProfiling")

        Profiling.enable(with: .init(applicationLaunchSampleRate: .maxSampleRate, continuousSampleRate: .maxSampleRate))
    }
}
