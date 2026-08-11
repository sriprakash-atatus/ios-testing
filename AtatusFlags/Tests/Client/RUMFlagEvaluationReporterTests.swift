/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddFlags` -> `AtatusFlags`, `ddInternal`
// -> `AtatusInternal`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusFlags

final class RUMFlagEvaluationReporterTests: XCTestCase {
    private let featureScope = FeatureScopeMock()

    func testSendFlagEvaluation() throws {
        // Given
        let reporter = RUMFlagEvaluationReporter(featureScope: featureScope)

        // When
        reporter.sendFlagEvaluation(
            flagKey: "feature-flag",
            value: true
        )

        // Then
        let messages = featureScope.messagesSent()
        XCTAssertEqual(messages.count, 1, "Should send flag evaluation message")

        let flagEvaluation = try XCTUnwrap(messages.firstPayload as? RUMFlagEvaluationMessage)
        XCTAssertEqual(flagEvaluation.flagKey, "feature-flag")
        XCTAssertEqual(flagEvaluation.value as? Bool, true)
    }
}
