/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

class TextFieldsViewController: UIViewController {
    @IBOutlet var textFields: [UITextField]!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Appears to be a bug in Xcode 26: Border style
        // from interface builder is not applied
        // https://stackoverflow.com/a/79796981
        textFields.forEach { textField in
            textField.borderStyle = .roundedRect
        }
    }
}
