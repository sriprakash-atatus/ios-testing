/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)
import Foundation
import QuartzCore

@available(iOS 13.0, tvOS 13.0, *)
extension CATransform3D {
    /// A Boolean value indicating whether the transform contains no rotation, skew, or perspective.
    var isAxisAligned: Bool {
        m12 == 0 && m21 == 0
            && m13 == 0 && m23 == 0
            && m31 == 0 && m32 == 0
            && m14 == 0 && m24 == 0
            && m34 == 0
    }
}
#endif
