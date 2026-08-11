/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusRUM

class FatalErrorContextNotifierTests: XCTestCase {
    private let featureScope = FeatureScopeMock()

    // MARK: - Changing Session State

    func testWhenSessionStateIsSet_itSendsSessionStateMessage() throws {
        // Given
        let fatalErrorContext = FatalErrorContextNotifier(messageBus: featureScope)
        let newSessionState: RUMSessionState = .mockRandom()

        // When
        fatalErrorContext.sessionState = newSessionState

        // Then
        let messages = featureScope.messagesSent()
        XCTAssertEqual(messages.count, 1)
        let sessionStateMessage = try XCTUnwrap(messages.lastPayload as? RUMSessionState)
        XCTAssertEqual(newSessionState, sessionStateMessage)
    }

    func testWhenSessionStateIsReset_itDoesNotSendNextSessionStateMessage() throws {
        // Given
        let fatalErrorContext = FatalErrorContextNotifier(messageBus: featureScope)
        let originalSessionState: RUMSessionState = .mockRandom()
        fatalErrorContext.sessionState = originalSessionState

        // When
        fatalErrorContext.sessionState = nil

        // Then
        let messages = featureScope.messagesSent()
        XCTAssertEqual(messages.count, 1)
        let sessionStateMessage = try XCTUnwrap(messages.lastPayload as? RUMSessionState)
        XCTAssertEqual(originalSessionState, sessionStateMessage)
    }

    // MARK: - Changing View State

    func testWhenViewIsSet_itSendsViewEventMessage() throws {
        // Given
        let fatalErrorContext = FatalErrorContextNotifier(messageBus: featureScope)
        let newViewEvent: RUMViewEvent = .mockRandom()

        // When
        fatalErrorContext.view = newViewEvent

        // Then
        let messages = featureScope.messagesSent()
        XCTAssertEqual(messages.count, 1)
        let viewEventMessage = try XCTUnwrap(messages.firstPayload as? RUMViewEvent)
        ATAssertJSONEqual(newViewEvent, viewEventMessage)
    }

    func testWhenViewIsReset_itSendsViewResetMessage() throws {
        // Given
        let fatalErrorContext = FatalErrorContextNotifier(messageBus: featureScope)
        fatalErrorContext.view = .mockRandom()

        // When
        fatalErrorContext.view = nil

        // Then
        let messages = featureScope.messagesSent()
        XCTAssertEqual(messages.count, 2)
        let viewEventMessage = try XCTUnwrap(messages.lastPayload as? String)
        XCTAssertEqual(viewEventMessage, RUMPayloadMessages.viewReset)
    }

    // MARK: - Changing Global Attributes

    func testWhenGlobalAttributesAreSet_itSendsAttributesMessage() throws {
        // Given
        let fatalErrorContext = FatalErrorContextNotifier(messageBus: featureScope)
        let newGlobalAttributes = mockRandomAttributes()

        // When
        fatalErrorContext.globalAttributes = newGlobalAttributes

        // Then
        let messages = featureScope.messagesSent()
        XCTAssertEqual(messages.count, 1)
        let attributesMessage = try XCTUnwrap(messages.lastPayload as? RUMEventAttributes)
        ATAssertJSONEqual(newGlobalAttributes, attributesMessage)
    }
}
