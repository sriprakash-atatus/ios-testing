/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)
import QuartzCore

/// A change observed on a `CALayer`.
///
/// It records which layer aspects changed: display, draw, layout, or any
/// combination of them.
internal struct CALayerChange: Sendable, Equatable {
    enum Aspect: Int8, CaseIterable, Sendable {
        case display
        case draw
        case layout

        struct Set: OptionSet, Sendable {
            let rawValue: Int8

            init(rawValue: Int8) {
                self.rawValue = rawValue
            }

            static let display = Self(rawValue: 1 << Aspect.display.rawValue)
            static let draw = Self(rawValue: 1 << Aspect.draw.rawValue)
            static let layout = Self(rawValue: 1 << Aspect.layout.rawValue)
        }
    }

    var layer: CALayerReference
    var aspects: Aspect.Set
}
#endif
