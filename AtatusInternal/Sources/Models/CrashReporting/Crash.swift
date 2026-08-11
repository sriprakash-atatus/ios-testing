/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation

public struct Crash {
    /// The crash report.
    public let report: ATCrashReport
    /// The crash context
    public let context: CrashContext

    /// Creates a Crash to be transmited on the message-bus.
    ///
    /// - Parameters:
    ///   - report: The crash report.
    ///   - context: The crash context
    public init(report: ATCrashReport, context: CrashContext) {
        self.report = report
        self.context = context
    }
}
