/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#if os(iOS)
import UIKit

// MARK: ATTextAndInputPrivacyLevelOverride
/// Text and input privacy override (e.g., mask or unmask specific text fields, labels, etc.).
@objc(ATTextAndInputPrivacyLevelOverride)
@_spi(objc)
public enum objc_TextAndInputPrivacyLevelOverride: Int {
    case none  // Represents `nil` in Swift
    case maskSensitiveInputs
    case maskAllInputs
    case maskAll

    internal var _swift: TextAndInputPrivacyLevel? {
        switch self {
        case .none: return nil
        case .maskSensitiveInputs: return .maskSensitiveInputs
        case .maskAllInputs: return .maskAllInputs
        case .maskAll: return .maskAll
        }
    }

    internal init(_ swift: TextAndInputPrivacyLevel?) {
        switch swift {
        case .maskSensitiveInputs: self = .maskSensitiveInputs
        case .maskAllInputs: self = .maskAllInputs
        case .maskAll: self = .maskAll
        case nil: self = .none
        }
    }
}

// MARK: ATImagePrivacyLevelOverride
/// Image privacy override (e.g., mask or unmask specific images).
@objc(ATImagePrivacyLevelOverride)
@_spi(objc)
public enum objc_ImagePrivacyLevelOverride: Int {
    case none  // Represents `nil` in Swift
    case maskNone
    case maskNonBundledOnly
    case maskAll

    internal var _swift: ImagePrivacyLevel? {
        switch self {
        case .none: return nil
        case .maskNone: return .maskNone
        case .maskNonBundledOnly: return .maskNonBundledOnly
        case .maskAll: return .maskAll
        }
    }

    internal init(_ swift: ImagePrivacyLevel?) {
        switch swift {
        case .maskNone: self = .maskNone
        case .maskNonBundledOnly: self = .maskNonBundledOnly
        case .maskAll: self = .maskAll
        case nil: self = .none
        }
    }
}

// MARK: ATTouchPrivacyLevelOverride
/// Touch privacy override (e.g., hide or show touch interactions on specific views).
@objc(ATTouchPrivacyLevelOverride)
@_spi(objc)
public enum objc_TouchPrivacyLevelOverride: Int {
    case none  // Represents `nil` in Swift
    case show
    case hide

    internal var _swift: TouchPrivacyLevel? {
        switch self {
        case .none: return nil
        case .show: return .show
        case .hide: return .hide
        }
    }

    internal init(_ swift: TouchPrivacyLevel?) {
        switch swift {
        case .show: self = .show
        case .hide: self = .hide
        case nil: self = .none
        }
    }
}
#endif
