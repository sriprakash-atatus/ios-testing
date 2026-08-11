/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS) || os(visionOS)

import UIKit

internal protocol UIScrollViewHandler: RUMCommandPublisher {
    /// Gets called on `scrollViewWillBeginDragging(_:)`.
    func notify_scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    /// Gets called on `scrollViewDidEndDragging(_:willDecelerate:)`.
    func notify_scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
    /// Gets called on `scrollViewDidEndDecelerating(_:)`.
    func notify_scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
}

#endif
