/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import UIKit
import AtatusCore

internal class TSConsentSettingViewController: UIViewController {

    @IBOutlet weak var consentValueControl: UISegmentedControl!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch homeViewController.currentConsentValue {
        case .granted: consentValueControl.selectedSegmentIndex = 0
        case .notGranted: consentValueControl.selectedSegmentIndex = 1
        case .pending: consentValueControl.selectedSegmentIndex = 2
        default: fatalError()
        }
    }

    @IBAction func didChangeConsentValue(_ sender: Any) {
        switch consentValueControl.selectedSegmentIndex {
        case 0:
            Atatus.set(trackingConsent: .granted)
            homeViewController.currentConsentValue = .granted
        case 1:
            Atatus.set(trackingConsent: .notGranted)
            homeViewController.currentConsentValue = .notGranted
        case 2:
            Atatus.set(trackingConsent: .pending)
            homeViewController.currentConsentValue = .pending
        default: fatalError()
        }
    }

    @IBAction func didTapClose(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private var homeViewController: TSHomeViewController {
        let parentNavigationVC = presentingViewController as! UINavigationController
        let homeViewController = parentNavigationVC.topViewController as! TSHomeViewController
        return homeViewController
    }
}
