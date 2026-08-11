// ATCHG: Atatus SDK migration - repointed the intake host at the Atatus site; rebranded the `dd` name
// to `Atatus` in comments and docs.

// Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
// This product includes software developed at Atatus (https://www.atatus.com/).
// Copyright 2026-Present Atatus, Inc.

import UIKit

internal class KioskViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        rumMonitor.startView(viewController: self, name: "KioskViewController")

        // Stop session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            rumMonitor.stopSession()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        rumMonitor.stopView(viewController: self)
    }
}
