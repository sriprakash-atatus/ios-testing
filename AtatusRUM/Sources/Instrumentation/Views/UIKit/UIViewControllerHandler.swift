/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if !os(watchOS)
import UIKit

internal protocol UIViewControllerHandler: RUMCommandPublisher {
    /// Gets called on `super.viewDidAppear()`.
    func notify_viewDidAppear(viewController: UIViewController, animated: Bool)
    /// Gets called on `super.viewDidDisappear()`.
    func notify_viewDidDisappear(viewController: UIViewController, animated: Bool)
}
#endif
