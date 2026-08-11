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

internal class CSHomeViewController: UIViewController {
    @IBAction func didTapTestLogging(_ sender: UIButton) {
        sender.disableFor(seconds: 0.5)
        logger?.info("test message")
    }

    @IBAction func didTapTestTracing(_ sender: UIButton) {
        sender.disableFor(seconds: 0.5)
        let span = Tracer.shared().startSpan(operationName: "test span")
        span.finish(at: Date(timeIntervalSinceNow: 1))
    }
}
