/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import XCTest
import TestUtilities

@testable import AtatusInternal

class AtatusCoreProtocolTests: XCTestCase {
    func testSendMessageExtension() {
        // Given
        let receiver = FeatureMessageReceiverMock()
        let core = PassthroughCoreMock(messageReceiver: receiver)

        // When
        core.send(message: .payload("value"))

        // Then
        XCTAssertEqual(
            receiver.messages.last?.asPayload as? String, "value", "AtatusCoreProtocol.send(message:) should forward message"
        )
    }

    func testAdditionalContextExtension() throws {
        // Given
        let core = PassthroughCoreMock()

        struct MyContext: AdditionalContext, Equatable {
            static let key = "my-context"
            let value: String
        }

        // When
        core.set(context: MyContext(value: "value"))

        // Then
        XCTAssertEqual(core.context.additionalContext(ofType: MyContext.self), MyContext(value: "value"))

        // When
        core.removeContext(ofType: MyContext.self)

        // Then
        XCTAssertNil(core.context.additionalContext(ofType: MyContext.self))
    }
}
