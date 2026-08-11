/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - removed the `dd` name from comments and docs; rebranded the licence
// header.

#if os(iOS)
import CoreGraphics
import UIKit

/// Computes `#RRGGBBAA` string for given `color`.
/// The implementation is pretty manual for better performance (using String format would be cleaner, but more heavy).
/// - Parameters:
///   - color: the color
/// - Returns: `#RRGGBBAA` string or `nil` if it cannot be constructed for given `color`.
internal func hexString(from color: CGColor) -> String? {
    guard let color = color.safeCast else {
        // Because `CGColor` is dynamic CF type it is possible to get some other CFTypeRef here.
        // To avoid crash on sending message to unexpected type, we sanitize here.
        // For full context, see: https://github.com/dd/atatus-sdk-ios/pull/1373
        return nil
    }

    return UIColor(cgColor: color).dd.hexString
}
#endif
