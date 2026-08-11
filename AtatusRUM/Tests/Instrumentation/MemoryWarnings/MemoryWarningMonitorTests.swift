/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; rebranded the licence
// header.

#if !os(watchOS)

import XCTest
@testable import AtatusRUM

final class MemoryWarningMonitorTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    var sut: MemoryWarningMonitor!
    // swiftlint:enable implicitly_unwrapped_optional
    let notificationCenter = NotificationCenter()

    func testStart_memoryWarningReported() throws {
        let didReport = expectation(description: "Memory warning reported")
        let memoryWarningMock = MemoryWarningReporterMock {
            didReport.fulfill()
        }
        sut = .init(
            memoryWarningReporter: memoryWarningMock,
            notificationCenter: notificationCenter
        )
        sut.start()
        notificationCenter.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        wait(for: [didReport], timeout: 0.5)
    }

    func testStop_memoryWarningNotReported() {
        let memoryWarningMock = MemoryWarningReporterMock {
            XCTFail("Memory warning should not be reported after `stop()`")
        }
        sut = .init(
            memoryWarningReporter: memoryWarningMock,
            notificationCenter: notificationCenter
        )
        sut.start()
        sut.stop()
        notificationCenter.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
}
#endif
