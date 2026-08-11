/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

#if os(iOS)

import AtatusInternal
import Foundation
import SwiftUI

@available(iOS 13.0, *)
extension SwiftUI.Path: AtatusExtended {}

@available(iOS 13.0, *)
extension AtatusExtension where ExtendedType == SwiftUI.Path {
    var svgString: String {
        var d = ""
        type.forEach { element in
            switch element {
            case let .move(to):
                d += "M \(to.dd.svgString) "
            case let .line(to):
                d += "L \(to.dd.svgString) "
            case let .quadCurve(to, control):
                d += "Q \(control.dd.svgString) \(to.dd.svgString) "
            case let .curve(to, control1, control2):
                d += "C \(control1.dd.svgString) \(control2.dd.svgString) \(to.dd.svgString) "
            case .closeSubpath:
                d += "Z "
            }
        }
        return d.trimmingCharacters(in: .whitespaces)
    }
}

extension CGPoint: AtatusExtended {}

extension AtatusExtension where ExtendedType == CGPoint {
    internal var svgString: String {
        "\(type.x.dd.svgString) \(type.y.dd.svgString)"
    }
}

extension CGFloat: AtatusExtended {}

extension AtatusExtension where ExtendedType == CGFloat {
    internal var svgString: String {
        String(format: "%.3f", locale: .init(identifier: "en_US_POSIX"), type)
    }
}

#endif
