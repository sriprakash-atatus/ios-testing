/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

internal class RUMTASVariousUIControllsViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTapOutside()
    }

    // MARK: - UITextField events

    @IBAction func textFieldDidEndEditing(_ sender: Any) {
    }

    // MARK: - UIStepper events

    @IBAction func stepperDidChangeValue(_ sender: Any) {
    }

    // MARK: - UISlider events

    @IBAction func sliderDidChangeValue(_ sender: Any) {
    }

    // MARK: - UISegmentedControl events

    @IBAction func segmentedControlDidChangeValue(_ sender: Any) {
    }

    // MARK: - UIBarButtonItem events

    @IBAction func didTapBarButtonItem(_ sender: Any) {
    }
}
