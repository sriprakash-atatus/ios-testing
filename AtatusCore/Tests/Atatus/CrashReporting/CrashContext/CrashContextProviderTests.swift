/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddCrashReporting` -> `AtatusCrashReporting`, `ddInternal` -> `AtatusInternal`, `ddLogs`
// -> `AtatusLogs`, `ddRUM` -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; renamed the `DD`
// symbol prefix to `AT`; rebranded the licence header.

import XCTest
#if canImport(CoreTelephony)
import CoreTelephony
#endif

import AtatusInternal
import TestUtilities

@testable import AtatusLogs
@testable import AtatusRUM
@testable import AtatusCrashReporting
@testable import AtatusCore

/// This suite tests if `CrashContextProvider` gets updated by different SDK components, each updating
/// separate part of the `CrashContext` information.
class CrashContextProviderTests: XCTestCase {
    private let provider = CrashContextCoreProvider()

    // MARK: - Receiving SDK Context

    func testWhenInitialSDKContextIsReceived_itNotifiesCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let sdkContext: AtatusContext = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(sdkContext), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: sdkContext)
    }

    func testWhenNextSDKContextIsReceived_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let nextSDKContext: AtatusContext = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(.mockRandom()), from: NOPAtatusCore())) // receive initial
        XCTAssertTrue(provider.receive(message: .context(nextSDKContext), from: NOPAtatusCore())) // receive next

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: nextSDKContext)
    }

    // MARK: - Receiving RUM View

    func testWhenRUMViewIsReceivedAfterSDKContext_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let sdkContext: AtatusContext = .mockRandom()
        let rumView: RUMViewEvent = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(sdkContext), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .payload(rumView), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: sdkContext)
        ATAssertJSONEqual(crashContext.lastRUMViewEvent, rumView, "Last RUM view must be available")
    }

    func testWhenSDKContextIsReceivedAfterRUMView_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let rumView: RUMViewEvent = .mockRandom()
        let nextSDKContext: AtatusContext = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(.mockRandom()), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(rumView), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .context(nextSDKContext), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: nextSDKContext)
        ATAssertJSONEqual(crashContext.lastRUMViewEvent, rumView, "Last RUM view must be available even after next SDK context update")
    }

    // MARK: - Receiving RUM View Reset

    func testWhenRUMViewResetIsReceivedAfterRUMView_thenItNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let sdkContext: AtatusContext = .mockRandom()
        let rumView: RUMViewEvent = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(sdkContext), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(rumView), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .payload(RUMPayloadMessages.viewReset), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: sdkContext)
        XCTAssertNil(crashContext.lastRUMViewEvent, "Last RUM view must reset")
    }

    func testWhenSDKContextIsReceivedAfterRUMViewReset_thenItNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let rumView: RUMViewEvent = .mockRandom()
        let nextSDKContext: AtatusContext = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(.mockRandom()), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(rumView), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .payload(RUMPayloadMessages.viewReset), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .context(nextSDKContext), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: nextSDKContext)
        XCTAssertNil(crashContext.lastRUMViewEvent, "Last RUM view must reset even after next SDK context update")
    }

    // MARK: - Receiving RUM Session State

    func testWhenRUMSessionStateIsReceivedAfterSDKContext_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let sdkContext: AtatusContext = .mockRandom()
        let rumSessionState: RUMSessionState = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(sdkContext), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(rumSessionState), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: sdkContext)
        XCTAssertEqual(crashContext.lastRUMSessionState, rumSessionState, "Last RUM session state must be available")
    }

    func testWhenSDKContextIsReceivedAfterRUMSessionState_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let rumSessionState: RUMSessionState = .mockRandom()
        let nextSDKContext: AtatusContext = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(.mockRandom()), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(rumSessionState), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .context(nextSDKContext), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: nextSDKContext)
        XCTAssertEqual(crashContext.lastRUMSessionState, rumSessionState, "Last RUM session state must be available even after next SDK context update")
    }

    // MARK: - Receiving Global RUM Attributes

    func testWhenRUMAttributesAreReceivedAfterSDKContext_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let sdkContext: AtatusContext = .mockRandom()
        let rumAttributes: RUMEventAttributes = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(sdkContext), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(rumAttributes), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: sdkContext)
        ATAssertJSONEqual(crashContext.lastRUMAttributes, rumAttributes, "Last RUM attributes must be available")
    }

    func testWhenSDKContextIsReceivedAfterRUMAttributes_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let rumAttributes: RUMEventAttributes = .mockRandom()
        let nextSDKContext: AtatusContext = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(.mockRandom()), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(rumAttributes), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .context(nextSDKContext), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: nextSDKContext)
        ATAssertJSONEqual(crashContext.lastRUMAttributes, rumAttributes, "Last RUM attributes must be available even after next SDK context update")
    }

    // MARK: - Receiving Global Log Attributes

    func testWhenLogAttributesAreReceivedAfterSDKContext_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let sdkContext: AtatusContext = .mockRandom()
        let logAttributes: LogEventAttributes = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(sdkContext), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(logAttributes), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: sdkContext)
        ATAssertJSONEqual(crashContext.lastLogAttributes, logAttributes, "Last Log attributes must be available")
    }

    func testWhenSDKContextIsReceivedAfterLogAttributes_itNotifiesNewCrashContext() throws {
        var latestCrashContext: CrashContext? = nil
        provider.onCrashContextChange = { latestCrashContext = $0 }

        // Given
        let logAttributes: LogEventAttributes = .mockRandom()
        let nextSDKContext: AtatusContext = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(.mockRandom()), from: NOPAtatusCore())) // receive initial SDK context
        XCTAssertTrue(provider.receive(message: .payload(logAttributes), from: NOPAtatusCore()))
        XCTAssertTrue(provider.receive(message: .context(nextSDKContext), from: NOPAtatusCore()))

        // Then
        provider.flush()
        let crashContext = try XCTUnwrap(latestCrashContext)
        XCTAssertEqual(crashContext, provider.currentCrashContext)
        ATAssert(crashContext: crashContext, includes: nextSDKContext)
        ATAssertJSONEqual(crashContext.lastLogAttributes, logAttributes, "Last Log attributes must be available even after next SDK context update")
    }

    // MARK: - Thread safety

    func testWhenContextIsWrittenAndReadFromDifferentThreads_itRunsAllOperationsSafely() {
        let provider = CrashContextCoreProvider()
        let viewEvent: RUMViewEvent = .mockRandom()
        let sessionState: RUMSessionState = .mockRandom()

        // swiftlint:disable opening_brace
        callConcurrently(
            closures: [
                { _ = provider.currentCrashContext },
                { _ = provider.receive(message: .context(.mockRandom()), from: NOPAtatusCore()) },
                { _ = provider.receive(message: .payload(viewEvent), from: NOPAtatusCore()) },
                { _ = provider.receive(message: .payload(RUMPayloadMessages.viewReset), from: NOPAtatusCore()) },
                { _ = provider.receive(message: .payload(sessionState), from: NOPAtatusCore()) },
            ],
            iterations: 50
        )
        // swiftlint:enable opening_brace

        provider.flush()
    }

    // MARK: - Helpers

    private func ATAssert(crashContext: CrashContext, includes sdkContext: AtatusContext, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(crashContext.appLaunchDate, sdkContext.launchInfo.processLaunchDate, file: file, line: line)
        XCTAssertEqual(crashContext.serverTimeOffset, sdkContext.serverTimeOffset, file: file, line: line)
        XCTAssertEqual(crashContext.service, sdkContext.service, file: file, line: line)
        XCTAssertEqual(crashContext.env, sdkContext.env, file: file, line: line)
        XCTAssertEqual(crashContext.version, sdkContext.version, file: file, line: line)
        XCTAssertEqual(crashContext.buildNumber, sdkContext.buildNumber, file: file, line: line)
        ATAssertReflectionEqual(crashContext.device, sdkContext.normalizedDevice(), file: file, line: line)
        ATAssertReflectionEqual(crashContext.os, sdkContext.os, file: file, line: line)
        XCTAssertEqual(crashContext.sdkVersion, sdkContext.sdkVersion, file: file, line: line)
        XCTAssertEqual(crashContext.source, sdkContext.source, file: file, line: line)
        XCTAssertEqual(crashContext.trackingConsent, sdkContext.trackingConsent, file: file, line: line)
        ATAssertReflectionEqual(crashContext.userInfo, sdkContext.userInfo, file: file, line: line)
        ATAssertReflectionEqual(crashContext.accountInfo, sdkContext.accountInfo, file: file, line: line)
        XCTAssertEqual(crashContext.networkConnectionInfo, sdkContext.networkConnectionInfo, file: file, line: line)
        XCTAssertEqual(crashContext.carrierInfo, sdkContext.carrierInfo, file: file, line: line)
        XCTAssertEqual(crashContext.lastIsAppInForeground, sdkContext.applicationStateHistory.currentState.isRunningInForeground, file: file, line: line)
    }
}
