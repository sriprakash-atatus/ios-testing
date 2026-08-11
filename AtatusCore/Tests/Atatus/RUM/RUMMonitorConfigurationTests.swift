/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded
// the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusRUM

class RUMMonitorConfigurationTests: XCTestCase {
    private let userInfo: UserInfo = .mockAny()
    private let networkConnectionInfo: NetworkConnectionInfo = .mockAny()
    private let carrierInfo: CarrierInfo = .mockAny()

    func testRUMMonitorConfiguration() throws {
        let expectation = expectation(description: "open feature scope")

        let core = AtatusCoreProxy(
            context: .mockWith(
                service: "service-name",
                env: "tests",
                version: "1.2.3",
                sdkVersion: "3.4.5",
                userInfo: userInfo,
                networkConnectionInfo: networkConnectionInfo,
                carrierInfo: carrierInfo
            )
        )
        defer { XCTAssertNoThrow(try core.flushAndTearDown()) }

        RUM.enable(
            with: .init(
                applicationID: "rum-123",
                sessionSampleRate: 42.5,
                trackAnonymousUser: false
            ),
            in: core
        )

        let monitor = RUMMonitor.shared(in: core).dd

        let dependencies = monitor.applicationScope.dependencies
        monitor.featureScope.eventWriteContext { context, _ in
            ATAssertReflectionEqual(context.userInfo, self.userInfo)
            XCTAssertEqual(context.networkConnectionInfo, self.networkConnectionInfo)
            XCTAssertEqual(context.carrierInfo, self.carrierInfo)

            XCTAssertEqual(context.service, "service-name")
            XCTAssertEqual(context.version, "1.2.3")
            XCTAssertEqual(context.sdkVersion, "3.4.5")

            expectation.fulfill()
        }

        XCTAssertEqual(dependencies.samplingRate, 42.5)
        XCTAssertEqual(monitor.applicationScope.context.rumApplicationID, "rum-123")
        waitForExpectations(timeout: 0.5)
    }
}
