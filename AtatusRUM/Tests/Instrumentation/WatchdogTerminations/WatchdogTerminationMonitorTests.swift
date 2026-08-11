/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed `com.ddhq.*` identifiers to `com.atatus.*`; rebranded the licence header.

import XCTest
import AtatusInternal
@testable import AtatusRUM
import TestUtilities

final class WatchdogTerminationMonitorTests: XCTestCase {
    let featureScope = FeatureScopeMock()

    // swiftlint:disable implicitly_unwrapped_optional
    var sut: WatchdogTerminationMonitor!
    var reporter: WatchdogTerminationReporterMock!
    // swiftlint:enable implicitly_unwrapped_optional

    func testApplicationWasInForeground_WatchdogTermination() throws {
        let didSend = self.expectation(description: "Watchdog termination was reported")

        // app starts - use a controlled queue so we can flush its state transitions
        let firstSessionQueue = DispatchQueue(label: "com.atatus.tests.first-session")
        given(
            isSimulator: false,
            isDebugging: false,
            appVersion: "1.0.0",
            osVersion: "1.0.0",
            systemBootTime: 1.0,
            vendorId: "foo",
            processId: UUID(),
            didCrash: false,
            didSend: didSend,
            queue: firstSessionQueue
        )

        // RUM view update before start, this must be ignored
        let viewEvent1: RUMViewEvent = .mockRandom()
        sut.update(viewEvent: viewEvent1)

        // monitor reveives the launch report
        _ = sut.receive(message: .context(featureScope.contextMock), from: NOPAtatusCore())

        // Flush the queue to ensure the monitor has transitioned to `.started`
        // before updating the view event. Without this, the update would be
        // dropped because the monitor is still in `.starting` state.
        firstSessionQueue.sync {}

        // RUM view update after start
        let viewEvent2: RUMViewEvent = .mockRandom()
        sut.update(viewEvent: viewEvent2)

        // watchdog termination happens here which causes app launch
        given(
            isSimulator: false,
            isDebugging: false,
            appVersion: "1.0.0",
            osVersion: "1.0.0",
            systemBootTime: 1.0,
            vendorId: "foo",
            processId: UUID(),
            didCrash: false,
            didSend: didSend
        )

        // RUM view update before start, this must be ignored
        let viewEvent3: RUMViewEvent = .mockRandom()
        sut.update(viewEvent: viewEvent3)

        // monitor reveives the launch report
        _ = sut.receive(message: .context(featureScope.contextMock), from: NOPAtatusCore())

        waitForExpectations(timeout: 1)
        XCTAssertEqual(reporter.sendParams?.viewEvent.view.id, viewEvent2.view.id)
    }

    // MARK: Helpers

    func given(
        isSimulator: Bool,
        isDebugging: Bool,
        appVersion: String,
        osVersion: String,
        systemBootTime: TimeInterval,
        vendorId: String?,
        processId: UUID,
        didCrash: Bool,
        didSend: XCTestExpectation,
        queue: DispatchQueue = AppStateManager.defaultQueue
    ) {
        let deviceInfo: DeviceInfo = .mockWith(
            isSimulator: isSimulator,
            vendorId: vendorId,
            isDebugging: false,
            systemBootTime: systemBootTime
        )

        featureScope.contextMock.version = appVersion
        featureScope.contextMock.device = deviceInfo
        featureScope.contextMock.set(additionalContext: LaunchReport(didCrash: didCrash))

        let appStateManager = AppStateManager(
            featureScope: featureScope,
            processId: processId,
            syntheticsEnvironment: false,
            queue: queue
        )

        let checker = WatchdogTerminationChecker(appStateManager: appStateManager, featureScope: featureScope)

        reporter = WatchdogTerminationReporterMock(didSend: didSend)

        sut = WatchdogTerminationMonitor(
            appStateManager: appStateManager,
            checker: checker,
            storage: NOPAtatusCore().storage,
            feature: featureScope,
            reporter: reporter
        )
    }
}
