/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

public enum BundleType: String, CaseIterable {
    /// An iOS application.
    case iOSApp
    /// An iOS app extension.
    case iOSAppExtension

    public init(bundle: Bundle) {
        self = bundle.bundlePath.hasSuffix(".appex") ? .iOSAppExtension : .iOSApp
    }
}
