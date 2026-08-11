/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

#if canImport(WatchKit)
import WatchKit

extension AtatusExtension where ExtendedType == WKExtension {
    public static var shared: WKExtension {
        .shared()
    }
}

extension WKExtension: AtatusExtended { }
#endif
