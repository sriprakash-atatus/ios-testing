/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/)
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddFlags` -> `AtatusFlags`, `ddInternal`
// -> `AtatusInternal`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities

@_spi(Internal)
@testable import AtatusFlags

class EvaluationAggregatorTests: XCTestCase {
    private let featureScope = FeatureScopeMock()

    // MARK: - Implementation Details

    func testGivenPendingAggregations_whenSendEvaluations_itClearsPending() {
        // Given
        let aggregator = EvaluationAggregator(
            dateProvider: DateProviderMock(now: .mockAny()),
            featureScope: featureScope,
            flushInterval: 100.0,
            maxAggregations: 1_000
        )

        // When
        aggregator.recordEvaluation(
            for: "flag-1",
            assignment: .mockAnyBoolean(),
            evaluationContext: .mockAny(),
            flagError: nil
        )
        aggregator.recordEvaluation(
            for: "flag-2",
            assignment: .mockAnyBoolean(),
            evaluationContext: .mockAny(),
            flagError: nil
        )

        // Then
        aggregator.sendEvaluations()
        XCTAssertEqual(featureScope.eventsWritten.count, 2)

        aggregator.recordEvaluation(
            for: "flag-3",
            assignment: .mockAnyBoolean(),
            evaluationContext: .mockAny(),
            flagError: nil
        )

        aggregator.sendEvaluations()
        XCTAssertEqual(featureScope.eventsWritten.count, 3, "Should have 2 from first flush + 1 from second flush")
    }

    // MARK: - Thread Safety

    func testGivenConcurrentAccess_whenRecordAndSend_itHandlesSafely() {
        // Given
        let aggregator = EvaluationAggregator(
            dateProvider: DateProviderMock(now: .mockAny()),
            featureScope: featureScope,
            flushInterval: 100.0,
            maxAggregations: 1_000
        )

        let iterations = 50
        let expectation = self.expectation(description: "All operations complete")
        expectation.expectedFulfillmentCount = iterations * 2

        // When
        DispatchQueue.global().async {
            for index in 0..<iterations {
                aggregator.recordEvaluation(
                    for: "flag-\(index)",
                    assignment: .mockAnyBoolean(),
                    evaluationContext: .mockAny(),
                    flagError: nil
                )
                expectation.fulfill()
            }
        }

        DispatchQueue.global().async {
            for _ in 0..<iterations {
                aggregator.sendEvaluations()
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 5.0)
        aggregator.sendEvaluations()

        XCTAssertEqual(featureScope.eventsWritten.count, 50, "Should have written exactly one event per unique flag")
    }
}
