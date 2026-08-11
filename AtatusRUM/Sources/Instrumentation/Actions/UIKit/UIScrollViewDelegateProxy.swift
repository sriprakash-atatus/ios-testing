/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUMPrivate` -> `AtatusRUMPrivate`; renamed
// the `__dd_private_*` ObjC symbols to `__atatus_private_*`; rebranded the licence header.

#if os(iOS) || os(visionOS)

import UIKit

// swiftlint:disable duplicate_imports
#if SPM_BUILD
    #if swift(>=6.0)
    internal import AtatusRUMPrivate
    #else
    @_implementationOnly import AtatusRUMPrivate
    #endif
#endif
// swiftlint:enable duplicate_imports

/// A proxy that wraps the original UIScrollView delegate to intercept scroll lifecycle events
/// while forwarding all calls to the original delegate transparently.
///
/// Inherits from `__atatus_private_DDForwardingProxyBase` so that any delegate selector forwarded
/// through this proxy is safely dropped (rather than crashing) when `originalDelegate` is
/// mid-dealloc. See RUM-16361.
internal final class UIScrollViewDelegateProxy: __atatus_private_DDForwardingProxyBase, UIScrollViewDelegate {
    /// The original delegate receiving forwarded calls.
    weak var originalDelegate: UIScrollViewDelegate?

    /// The handler notified of scroll lifecycle events.
    var handler: UIScrollViewHandler

    init(
        originalDelegate: UIScrollViewDelegate?,
        handler: UIScrollViewHandler
    ) {
        self.handler = handler
        self.originalDelegate = originalDelegate
        super.init()
    }

    // MARK: - UIScrollViewDelegate (intercepted)

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        handler.notify_scrollViewWillBeginDragging(scrollView)
        originalDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        handler.notify_scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        originalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handler.notify_scrollViewDidEndDecelerating(scrollView)
        originalDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    // MARK: - Forwarding

    /// Provides the current forwarding target to `__atatus_private_DDForwardingProxyBase`.
    /// When `originalDelegate` is `nil` (e.g. mid-dealloc), the base class returns a benign
    /// method signature and silently drops the invocation in `forwardInvocation:` — closing
    /// the `unrecognized selector` crash family (RUM-16361, GH #2867).
    override func forwardingTargetOrNil() -> Any? {
        return originalDelegate
    }

    /// Guards against re-entrant calls to `responds(to:)` that arise when a third-party
    /// delegate proxy (e.g. RxSwift's `DelegateProxy`) and this proxy hold mutual references,
    /// causing infinite recursion.
    private var isRespondingToSelector = false

    // swiftlint:disable:next implicitly_unwrapped_optional
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        guard !isRespondingToSelector else {
            return false
        }
        isRespondingToSelector = true
        defer { isRespondingToSelector = false }
        return originalDelegate?.responds(to: aSelector) ?? false
    }
}

#endif
