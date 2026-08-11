/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)
import Foundation
import CoreGraphics

/// Describes a sequence of touch information over time.
internal struct TouchSnapshot {
    /// A single touch information.
    struct Touch {
        /// An unique identifier of the touch. It persists throughout a multi-touch sequence (it is created on "touch down",
        /// continues through "touch move" and ends in "touch up").
        let id: TouchIdentifier
        /// Phase of the touch as distinguished in session replay.
        let phase: TouchPhase
        /// A time of recording this touch
        var date: Date
        /// The position of this touch in application window.
        let position: CGPoint
        /// The touch override associated with the touch's view
        let touchOverride: TouchPrivacyLevel?
    }

    enum TouchPhase {
        case down
        case move
        case up
    }

    /// The time of the earliest touch.
    let date: Date
    /// Touches recorded in this snapshot.
    let touches: [Touch]
}
#endif
