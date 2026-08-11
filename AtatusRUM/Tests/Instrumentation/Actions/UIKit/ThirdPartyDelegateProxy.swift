/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if !os(tvOS) && !os(watchOS)

import UIKit

/// Simulates a third-party delegate proxy (e.g. RxSwift's `DelegateProxy`) that stores a
/// forward-to delegate and calls `responds(to:)` on it — the same pattern that causes
/// circular recursion when combined with `UIScrollViewDelegateProxy`.
internal class ThirdPartyDelegateProxy: NSObject, UIScrollViewDelegate {
    weak var forwardToDelegate: (NSObject & UIScrollViewDelegate)?

    // swiftlint:disable:next implicitly_unwrapped_optional
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        return forwardToDelegate?.responds(to: aSelector) ?? false
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let fwd = forwardToDelegate, fwd.responds(to: aSelector) {
            return fwd
        }
        return super.forwardingTarget(for: aSelector)
    }
}

#endif
