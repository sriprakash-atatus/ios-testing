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

final class CALayerObserverMock: CALayerObserver {
    var layerDidDisplayCalls: [CALayer] = []
    var layerDidDrawCalls: [(layer: CALayer, context: CGContext)] = []
    var layerDidLayoutSublayersCalls: [CALayer] = []

    func layerDidDisplay(_ layer: CALayer) {
        layerDidDisplayCalls.append(layer)
    }

    func layerDidDraw(_ layer: CALayer, in context: CGContext) {
        layerDidDrawCalls.append((layer, context))
    }

    func layerDidLayoutSublayers(_ layer: CALayer) {
        layerDidLayoutSublayersCalls.append(layer)
    }
}
#endif
