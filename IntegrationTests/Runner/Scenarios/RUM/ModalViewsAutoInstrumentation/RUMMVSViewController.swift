/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

/// The VC which presents another VC modally.
class RUMMVSViewController: UIViewController {
    @IBAction func didTapPresentModallyFromCode(_ sender: Any) {
        let modalViewController = storyboard!.instantiateViewController(withIdentifier: "ModalVC")

        if Bool.random() {
            present(modalViewController, animated: true) { /* empty completion block */ }
        } else {
            present(modalViewController, animated: true)
        }
    }

    /// This method gets called from presented view controller.
    func dismissPresentedViewController() {
        if Bool.random() {
            dismiss(animated: true) { /* empty completion block */ }
        } else {
            dismiss(animated: true)
        }
    }
}
