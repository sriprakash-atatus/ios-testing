/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

internal final class BacktraceReportingFeature: AtatusFeature {
    static var name: String = "backtrace-reporting"

    let messageReceiver: FeatureMessageReceiver = NOPFeatureMessageReceiver()

    /// A type capable of generating backtrace reports.
    let reporter: BacktraceReporting

    /// Creates `BacktraceReportingFeature`.
    /// - Parameter reporter: An external implementation of a type capable of generating backtrace reports.
    init(reporter: BacktraceReporting) {
        self.reporter = reporter
    }
}
