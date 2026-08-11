/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; rebranded the licence
// header.

import UIKit
import AtatusRUM

final class RUMFeatureOperationsNextViewController: UIViewController {

    @IBAction func didTapSucceedLoginFlowButton(_ sender: Any) {
        rumMonitor.succeedOperation(
            name: Operation.login()
        )
    }
}
