/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddFlags` -> `AtatusFlags`, `ddInternal`
// -> `AtatusInternal`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities

@_spi(Internal)
@testable import AtatusFlags

final class EvaluationLoggerMock: EvaluationLogging {
    var logEvaluationCalls: [(
        flagKey: String,
        assignment: FlagAssignment,
        context: FlagsEvaluationContext,
        error: String?
    )] = []

    func logEvaluation(
        for flagKey: String,
        assignment: FlagAssignment,
        evaluationContext: FlagsEvaluationContext,
        flagError: String?
    ) {
        logEvaluationCalls.append((flagKey, assignment, evaluationContext, flagError))
    }
}
