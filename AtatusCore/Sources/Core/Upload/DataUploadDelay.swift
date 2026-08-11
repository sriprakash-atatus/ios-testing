/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// Mutable interval used for periodic data uploads.
internal class DataUploadDelay {
    private let minDelay: TimeInterval
    private let maxDelay: TimeInterval
    private let changeRate: Double

    private(set) var current: TimeInterval
    let maxJitter: TimeInterval

    init(performance: UploadPerformancePreset) {
        self.minDelay = performance.minUploadDelay
        self.maxDelay = performance.maxUploadDelay
        self.changeRate = performance.uploadDelayChangeRate
        self.maxJitter = performance.maxUploadJitter
        self.current = performance.initialUploadDelay
    }

    func reset() {
        current = minDelay
    }

    func increase() {
        current = min(current * (1.0 + changeRate), maxDelay)
    }
}
