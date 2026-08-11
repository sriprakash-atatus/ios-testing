/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCrashReporting` -> `AtatusCrashReporting`,
// `ddInternal` -> `AtatusInternal`; renamed `dd*` types to `Atatus*`; rebranded the licence
// header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusCrashReporting

class CrashContextCoreProviderTests: XCTestCase {
    // MARK: - Context Update Tests

    func testItUpdatesContextFromAtatusContext() {
        // Given
        let provider = CrashContextCoreProvider()
        let core = PassthroughCoreMock()
        let context: AtatusContext = .mockWith(
            service: "test-service",
            env: "test-env",
            version: "1.0.0"
        )

        // When
        let message: FeatureMessage = .context(context)
        XCTAssertTrue(provider.receive(message: message, from: core))
        provider.flush()

        // Then
        XCTAssertNotNil(provider.currentCrashContext)
        XCTAssertEqual(provider.currentCrashContext?.service, "test-service")
        XCTAssertEqual(provider.currentCrashContext?.env, "test-env")
        XCTAssertEqual(provider.currentCrashContext?.version, "1.0.0")
    }

    func testItDoesNotUpdateContextWhenContextIsUnchanged() {
        // Given
        let provider = CrashContextCoreProvider()
        let core = PassthroughCoreMock()
        let context: AtatusContext = .mockWith(service: "test-service")
        var callbackCount = 0

        provider.onCrashContextChange = { _ in
            callbackCount += 1
        }

        // When
        XCTAssertTrue(provider.receive(message: .context(context), from: core))
        XCTAssertTrue(provider.receive(message: .context(context), from: core))
        provider.flush()

        // Then - callback should only be called once for the actual change
        XCTAssertEqual(callbackCount, 1)
    }

    // MARK: - RUM View Event Tests

    func testItStoresRUMViewEvent() {
        // Given
        let provider = CrashContextCoreProvider()
        let core = PassthroughCoreMock()
        let context: AtatusContext = .mockAny()
        let viewEvent: RUMViewEvent = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(context), from: core))
        XCTAssertTrue(provider.receive(message: .payload(viewEvent), from: core))
        provider.flush()

        // Then
        XCTAssertNotNil(provider.currentCrashContext?.lastRUMViewEvent)
        XCTAssertEqual(provider.currentCrashContext?.lastRUMViewEvent?.view.id, viewEvent.view.id)
    }

    func testItResetsRUMViewEventOnViewReset() {
        // Given
        let provider = CrashContextCoreProvider()
        let core = PassthroughCoreMock()
        let context: AtatusContext = .mockAny()
        let viewEvent: RUMViewEvent = .mockRandom()

        XCTAssertTrue(provider.receive(message: .context(context), from: core))
        XCTAssertTrue(provider.receive(message: .payload(viewEvent), from: core))
        provider.flush()

        XCTAssertNotNil(provider.currentCrashContext?.lastRUMViewEvent)

        // When
        XCTAssertTrue(provider.receive(message: .payload(RUMPayloadMessages.viewReset), from: core))
        provider.flush()

        // Then
        XCTAssertNil(provider.currentCrashContext?.lastRUMViewEvent)
    }

    // MARK: - RUM Session State Tests

    func testItStoresRUMSessionState() {
        // Given
        let provider = CrashContextCoreProvider()
        let core = PassthroughCoreMock()
        let context: AtatusContext = .mockAny()
        let sessionState: RUMSessionState = .mockRandom()

        // When
        XCTAssertTrue(provider.receive(message: .context(context), from: core))
        XCTAssertTrue(provider.receive(message: .payload(sessionState), from: core))
        provider.flush()

        // Then
        XCTAssertNotNil(provider.currentCrashContext?.lastRUMSessionState)
        XCTAssertEqual(provider.currentCrashContext?.lastRUMSessionState?.sessionUUID, sessionState.sessionUUID)
    }

    // MARK: - Callback Tests

    func testItInvokesCallbackOnContextChange() {
        // Given
        let provider = CrashContextCoreProvider()
        let core = PassthroughCoreMock()
        let context: AtatusContext = .mockWith(service: "test-service")
        var receivedContext: CrashContext?

        provider.onCrashContextChange = { crashContext in
            receivedContext = crashContext
        }
        provider.flush()

        // When
        XCTAssertTrue(provider.receive(message: .context(context), from: core))
        provider.flush()

        // Then
        XCTAssertNotNil(receivedContext)
        XCTAssertEqual(receivedContext?.service, "test-service")
    }

    // MARK: - Message Handling Tests

    func testItReturnsFalseForUnhandledMessages() {
        // Given
        let provider = CrashContextCoreProvider()
        let core = PassthroughCoreMock()
        let unrelatedMessage = "some unrelated message"

        // When
        let handled = provider.receive(message: .payload(unrelatedMessage), from: core)

        // Then
        XCTAssertFalse(handled)
    }
}
