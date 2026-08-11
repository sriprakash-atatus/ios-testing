/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddTrace` ->
// `AtatusTrace`; rebranded the licence header.

import UIKit
import AtatusCore
import AtatusTrace

internal class CSRootViewController: UIViewController {
    @IBAction func startCore(_ sender: UIButton) {
        appConfiguration.initializeSDK()
    }

    @IBAction func stopCore(_ sender: UIButton) {
        appConfiguration.deinitializeSDK()
    }
}
