/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

/// Returns `true` if the warning was raised. `false` otherwise.
internal func warn(if condition: @autoclosure () -> Bool, message: String) -> Bool {
    if condition() {
        AT.logger.warn(message)
        return true
    } else {
        return false
    }
}

/// Returns `nil` if the warning was raised. `T` otherwise.
internal func warnIfCannotCast<T>(value: Any) -> T? {
    guard let castedValue = value as? T else {
        AT.logger.warn("🔥 Using \(type(of: value as Any)) while \(T.self) was expected.")
        return nil
    }
    return castedValue
}
