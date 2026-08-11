/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddTrace` ->
// `AtatusTrace`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence
// header.

import Foundation
import SwiftUI

import AtatusCore
import AtatusTrace

struct TraceScenario: Scenario {
    var initialViewController: UIViewController {
        UIHostingController(rootView: TraceContentView())
    }

    func instrument(with info: AppInfo) {
        Atatus.initialize(
            with: .benchmark(info: info),
            trackingConsent: .granted
        )

        Trace.enable()
    }
}
