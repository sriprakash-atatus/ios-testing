/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

extension UIButton {
    func disableFor(seconds: TimeInterval) {
        let completion = disableUntilCompletion()
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    func disableUntilCompletion() -> () -> Void {
        let originalBackgroundColor = self.backgroundColor

        self.isEnabled = false
        self.backgroundColor = .systemGray

        return {
            self.isEnabled = true
            self.backgroundColor = originalBackgroundColor
        }
    }
}
