/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if os(iOS)

import SwiftUI
import AtatusInternal

@available(iOS 13.0, tvOS 13.0, *)
extension GraphicsFilter: Reflection {
    init(from reflector: Reflector) throws {
        switch (reflector.displayStyle, reflector.descendantIfPresent(0)) {
        case let (.enum("colorMultiply"), color):
            if #available(iOS 26, tvOS 26, *) {
                self = try .colorMultiply(reflector.reflect(type: Color._ResolvedHDR.self, color).base)
            } else {
                self = try .colorMultiply(reflector.reflect(color))
            }
        default:
            self = .unknown
        }
    }
}

#endif
