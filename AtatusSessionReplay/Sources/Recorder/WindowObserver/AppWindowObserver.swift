/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)
import UIKit

/// A type observing the application object and finding the most relevant window for session replay recording.
internal protocol AppWindowObserver {
    var relevantWindow: UIWindow? { get }
}
#endif
