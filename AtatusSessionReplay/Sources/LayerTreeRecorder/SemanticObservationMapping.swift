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
extension CALayerSnapshot {
    struct SemanticObservationMapping {
        let observe: @MainActor (
            _ layer: CALayer,
            _ absoluteFrame: CGRect,
            _ context: CALayerSnapshot.Context
        ) -> SemanticObservation?
    }
}

@available(iOS 13.0, tvOS 13.0, *)
extension CALayerSnapshot.SemanticObservationMapping: CaseIterable {
    static let allCases: [Self] = [
        .embeddedContent,
        .gradient,
        .activityIndicator,
        .label,
        .imageView,
        .textView,
        .textField,
        .webView,
        .control,
        .progressView,
        .barBackground,
        // visual effects
        .signedDistanceField,
        .destinationOutView,
        .portal,
        .automaticCapsule,
        .glassGroup,
        .scrollPocket,
        .captureOnlyBackdrop,
        .visualEffectBackdrop,
        .visualEffectBackground,
        .liquidLens
    ]
}
#endif
