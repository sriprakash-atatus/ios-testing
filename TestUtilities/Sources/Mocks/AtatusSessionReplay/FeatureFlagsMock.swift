/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)

import Foundation

@_spi(Internal)
@testable import AtatusSessionReplay

extension SessionReplay.Configuration.FeatureFlags {
    public static var allEnabled: Self {
        var flags: Self = [
            .swiftui: true,
            .heatmaps: true,
        ]

        if #available(iOS 13.0, tvOS 13.0, *) {
            flags[.compositionTreeRecording] = true
        }

        return flags
    }
}

#endif
