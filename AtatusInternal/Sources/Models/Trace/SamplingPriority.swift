/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// The sampling priority for a trace span.
public enum SamplingPriority: Int, Sendable {
    /// The span is not sampled based on a manual override.
    case manualDrop = -1
    /// The span is not sampled based on a sampler decision.
    case autoDrop = 0
    /// The span is sampled based on a sampler decision.
    case autoKeep = 1
    /// The span is sampled based on a manual override.
    case manualKeep = 2

    /// `true` if the span is sampled, `false` otherwise.
    public var isKept: Bool {
        switch self {
        case .manualDrop, .autoDrop: false
        case .manualKeep, .autoKeep: true
        }
    }

    init?(string: any StringProtocol) {
        guard let intValue = Int(string) else {
            return nil
        }
        self.init(rawValue: intValue)
    }
}
