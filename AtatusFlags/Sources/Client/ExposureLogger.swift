/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

internal protocol ExposureLogging {
    func logExposure(
        for flagKey: String,
        assignment: FlagAssignment,
        evaluationContext: FlagsEvaluationContext
    )
}

internal final class ExposureLogger: ExposureLogging {
    private let dateProvider: any DateProvider
    private let featureScope: any FeatureScope
    private let loggedExposures = ExposureTracker()

    init(dateProvider: any DateProvider, featureScope: any FeatureScope) {
        self.dateProvider = dateProvider
        self.featureScope = featureScope
    }

    func logExposure(
        for flagKey: String,
        assignment: FlagAssignment,
        evaluationContext: FlagsEvaluationContext
    ) {
        guard assignment.doLog else {
            return
        }

        featureScope.eventWriteContext { [weak self] context, writer in
            guard let self else {
                return
            }

            let exposure = ExposureTracker.Exposure(
                targetingKey: evaluationContext.targetingKey,
                flagKey: flagKey,
                allocationKey: assignment.allocationKey,
                variationKey: assignment.variationKey
            )

            guard loggedExposures.track(exposure) else {
                return
            }

            let date = dateProvider.now.addingTimeInterval(context.serverTimeOffset)
            let exposureEvent = ExposureEvent(
                timestamp: date.timeIntervalSince1970.dd.toInt64Milliseconds,
                allocation: .init(key: assignment.allocationKey),
                flag: .init(key: flagKey),
                variant: .init(key: assignment.variationKey),
                subject: .init(
                    id: evaluationContext.targetingKey,
                    attributes: evaluationContext.attributes
                )
            )

            writer.write(value: exposureEvent)
        }
    }
}

// MARK: - NOPExposureLogger

internal final class NOPExposureLogger: ExposureLogging {
    func logExposure(
        for flagKey: String,
        assignment: FlagAssignment,
        evaluationContext: FlagsEvaluationContext
    ) {
        // No-op: exposure logging is disabled
    }
}
