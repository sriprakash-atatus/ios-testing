/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

internal class SendRUMFixture2ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        rumMonitor.startView(viewController: self, name: "SendRUMFixture2View")

        rumMonitor.addFeatureFlagEvaluation(name: "mock_flag_a", value: false)
        rumMonitor.addFeatureFlagEvaluation(name: "mock_flag_b", value: "mock_value")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            rumMonitor.addError(message: "Simulated view error", source: .source)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        rumMonitor.stopView(viewController: self)
    }
}
