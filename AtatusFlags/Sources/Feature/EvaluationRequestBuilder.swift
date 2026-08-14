/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `dd*` members to `at*`; renamed `clientToken` to `licenseKey`;
// renamed the `ddsource` / `ddtags` query parameters to `atatus_source` / `atatustags`; rebranded the
// licence header.

import Foundation
import AtatusInternal

internal struct EvaluationRequestBuilder: FeatureRequestBuilder {
    let customIntakeURL: URL?
    let telemetry: Telemetry

    func request(for events: [Event], with context: AtatusContext, execution: ExecutionContext) throws -> URLRequest {
        let evaluationEvents: [FlagEvaluationEvent] = try events.map { event in
            guard let evaluation = try? JSONDecoder().decode(FlagEvaluationEvent.self, from: event.data) else {
                throw InternalError(description: "Failed to decode FlagEvaluationEvent from Event data")
            }
            return evaluation
        }

        let batchContext = buildEvaluationContext(from: context)
        let batchedEvaluations = BatchedFlagEvaluations(
            context: batchContext,
            flagEvaluations: evaluationEvents
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let jsonData = try encoder.encode(batchedEvaluations)

        let builder = URLRequestBuilder(
            url: url(with: context),
            queryItems: [
                .atatusSource(source: context.source)
            ],
            headers: [
                .contentTypeHeader(contentType: .applicationJSON),
                .userAgentHeader(
                    appName: context.applicationName,
                    appVersion: context.version,
                    device: context.device,
                    os: context.os
                ),
                .atAPIKeyHeader(licenseKey: context.licenseKey),
                .atEVPOriginHeader(source: context.ciAppOrigin ?? context.source),
                .atEVPOriginVersionHeader(sdkVersion: context.sdkVersion),
                .atRequestIDHeader()
            ],
            telemetry: telemetry
        )

        return builder.uploadRequest(with: jsonData, compress: false)
    }

    private func url(with context: AtatusContext) -> URL {
        // ATCHG: Built from `intakeEndpoint` so a custom `serverUrl` is honoured, matching
        // `EvaluationsRequestFactory.create` on Android.
        customIntakeURL ?? context.intakeEndpoint.appendingPathComponent("api/v2/flagevaluation")
        // ATCHG: End
    }

    private func buildEvaluationContext(from context: AtatusContext) -> EvaluationContext {
        return EvaluationContext(
            geo: nil,
            device: EvaluationContext.DeviceInfo(
                name: context.device.name,
                type: context.device.type.normalizedDeviceType,
                brand: context.device.brand,
                model: context.device.model
            ),
            os: EvaluationContext.OSInfo(
                name: context.os.name,
                version: context.os.version
            ),
            service: context.service,
            version: context.version,
            env: context.env,
            rum: buildRumContext(from: context)
        )
    }

    private func buildRumContext(from context: AtatusContext) -> EvaluationContext.RUMInfo? {
        guard let rum = context.additionalContext(ofType: RUMCoreContext.self) else {
            return nil
        }
        return EvaluationContext.RUMInfo(
            application: EvaluationContext.RUMInfo.ApplicationInfo(id: rum.applicationID),
            view: nil // viewURL not available in RUMCoreContext
        )
    }
}
