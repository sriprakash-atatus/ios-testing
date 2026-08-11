/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation

@objc(ATCoreLoggerLevel)
@_spi(objc)
public enum objc_CoreLoggerLevel: Int {
    case none
    case debug
    case warn
    case error
    case critical
}
