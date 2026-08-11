/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Describe the battery state for mobile devices.
public struct BatteryStatus: Codable, Equatable {
    public enum State: Codable {
        case unknown
        case unplugged
        case charging
        case full
    }

    /// The charging state of the battery.
    public let state: State

    /// The battery power level, range between 0 and 1.
    public let level: Float

    public init(state: State, level: Float) {
        self.state = state
        self.level = level
    }
}
