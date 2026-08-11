/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// Launch report format supported by Atatus SDK.
public struct LaunchReport: AdditionalContext {
    /// The key used to encode/decode the `LaunchReport` in `AtatusContext.baggages`
    public static let key = "launch-report"

    /// Returns `true` if the previous session crashed.
    public let didCrash: Bool

    ///  Creates a new `LaunchReport`.
    /// - Parameter didCrash: `true` if the previous session crashed.
    public init(didCrash: Bool) {
        self.didCrash = didCrash
    }
}

extension LaunchReport: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
        LaunchReport
        - didCrash: \(didCrash)
        """
    }
}
