/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)

import SwiftUI

@available(iOS 13.0, tvOS 13.0, *)
internal enum GraphicsFilter {
    case colorMultiply(Color._Resolved)
    case unknown
}

#endif
