/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; rebranded the licence header.

import XCTest
import AtatusInternal
@testable import TestUtilities

@testable import AtatusRUM

class FlagEvaluationReceiverTests: XCTestCase {
    private let featureScope = FeatureScopeMock()

    func testReceiveFlagEvaluationMessage() throws {
        // Given
        let receiver = FlagEvaluationReceiver(
            monitor: Monitor(
                dependencies: .mockWith(featureScope: featureScope),
                dateProvider: SystemDateProvider()
            )
        )
        let message: FeatureMessage = .payload(
            RUMFlagEvaluationMessage(
                flagKey: "feature-flag",
                value: true
            )
        )

        // When
        let result = receiver.receive(message: message, from: NOPAtatusCore())

        // Then
        XCTAssertTrue(result, "It must accept the message")

        let viewEvents: [RUMViewEvent] = featureScope.eventsWritten()
        XCTAssertFalse(viewEvents.isEmpty, "It should write a view event")

        let lastViewEvent = try XCTUnwrap(viewEvents.last)
        let featureFlags = try XCTUnwrap(lastViewEvent.featureFlags)
        XCTAssertEqual(featureFlags.featureFlagsInfo["feature-flag"] as? Bool, true)
    }
}
