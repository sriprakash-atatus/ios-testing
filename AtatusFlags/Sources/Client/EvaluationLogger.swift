/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

internal protocol EvaluationLogging {
    func logEvaluation(
        for flagKey: String,
        assignment: FlagAssignment,
        evaluationContext: FlagsEvaluationContext,
        flagError: String?
    )
}

internal final class EvaluationLogger: EvaluationLogging {
    private let aggregator: EvaluationAggregator

    init(aggregator: EvaluationAggregator) {
        self.aggregator = aggregator
    }

    func logEvaluation(
        for flagKey: String,
        assignment: FlagAssignment,
        evaluationContext: FlagsEvaluationContext,
        flagError: String?
    ) {
        aggregator.recordEvaluation(
            for: flagKey,
            assignment: assignment,
            evaluationContext: evaluationContext,
            flagError: flagError
        )
    }
}

internal final class NOPEvaluationLogger: EvaluationLogging {
    func logEvaluation(
        for flagKey: String,
        assignment: FlagAssignment,
        evaluationContext: FlagsEvaluationContext,
        flagError: String?
    ) {
        // No-op
    }
}
