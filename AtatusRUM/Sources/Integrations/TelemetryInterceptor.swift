/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

/// Intercepts telemetry events sent through message bus.
internal struct TelemetryInterceptor: FeatureMessageReceiver {
    /// "RUM Session Ended" controller to count SDK errors.
    let sessionEndedMetric: SessionEndedMetricController

    func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        guard case .telemetry(let telemetry) = message else {
            return false
        }

        switch telemetry {
        case .error(let id, let message, let kind, let stack):
            interceptError(id: id, message: message, kind: kind, stack: stack)
        case .metric(let metric) where metric.name == UploadQualityMetric.name:
            // Intercept the 'upload_quality' metric for aggregation in the rse
            // metric
            interceptUploadQualityMetric(attributes: metric.attributes)
            return true // do not forward the message

        default:
            break
        }

        return false // do not consume, pass to next receivers
    }

    private func interceptError(id: String, message: String, kind: String, stack: String) {
        sessionEndedMetric.track(sdkErrorKind: kind, in: nil) // `nil` - track in current session
    }

    private func interceptUploadQualityMetric(attributes: [String: Encodable]) {
        sessionEndedMetric.track(uploadQuality: attributes, in: nil) // `nil` - track in current session
    }
}
