/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension AtatusExtension where ExtendedType == UIApplication {
    /// `UIApplication.shared` does not compile in some environments (e.g. notification service app extension), resulting with:
    /// _"shared' is unavailable in application extensions for iOS: Use view controller based solutions where appropriate instead"_.
    ///
    /// As a workaround, this `managedShared` utility provides a key-path access to the `UIApplication.shared` to make the compiler pass.
    public static var managedShared: UIApplication? {
        return UIApplication
            .value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication // swiftlint:disable:this unsafe_uiapplication_shared
    }
}

extension UIApplication: AtatusExtended { }
#endif
