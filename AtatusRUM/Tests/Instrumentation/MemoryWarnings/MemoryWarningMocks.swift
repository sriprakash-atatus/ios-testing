/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; rebranded the licence
// header.

import XCTest
@testable import AtatusRUM
import TestUtilities

final class MemoryWarningReporterMock: MemoryWarningReporting {
    let didReportMemoryWarning: () -> Void

    init(didReport: @escaping () -> Void) {
        self.didReportMemoryWarning = didReport
    }

    func reportMemoryWarning() {
        didReportMemoryWarning()
    }

    /// nop
    func publish(to subscriber: any AtatusRUM.RUMCommandSubscriber) {
    }
}

extension MemoryWarningMonitor: RandomMockable {
    public static func mockRandom() -> MemoryWarningMonitor {
        return .init(
            memoryWarningReporter: MemoryWarningReporterMock.mockRandom(),
            notificationCenter: .default
        )
    }
}

extension MemoryWarningReporterMock: RandomMockable {
    static func mockRandom() -> MemoryWarningReporterMock { .init {}}
}
