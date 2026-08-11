/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)
import QuartzCore

@testable import AtatusSessionReplay

@available(iOS 13.0, tvOS 13.0, *)
extension CALayerChangeset {
    static func mockChange(for layer: CALayer, aspects: CALayerChange.Aspect.Set) -> CALayerChangeset {
        CALayerChangeset(
            [ObjectIdentifier(layer): CALayerChange(layer: .init(layer), aspects: aspects)]
        )
    }
}
#endif
