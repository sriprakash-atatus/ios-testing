/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusTrace

class ContextMessageReceiverTests: XCTestCase {
    func testItReceivesApplicationStateHistory() throws {
        // Given
        let receiver = ContextMessageReceiver(samplerProvider: SamplerProvider(sampleRate: .mockAny()))
        let core = PassthroughCoreMock(
            context: .mockWith(applicationStateHistory: .mockAppInBackground()),
            messageReceiver: receiver
        )

        XCTAssertEqual(receiver.context.applicationStateHistory?.currentState, .background)

        // When
        core.context.applicationStateHistory.append(state: .active, at: Date())

        // Then
        XCTAssertEqual(receiver.context.applicationStateHistory?.currentState, .active)
    }
}
