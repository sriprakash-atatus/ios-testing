/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `dd*` members to `at*`; renamed `clientToken` to `licenseKey`;
// renamed the `ddsource` / `ddtags` query parameters to `atatus_source` / `atatustags`; moved the intake
// path to `/v1/ios/*`; rebranded the licence header.

import Foundation
import AtatusInternal

/// The RUM URL Request Builder for formatting and configuring the `URLRequest`
/// to upload RUM data.
internal struct RequestBuilder: FeatureRequestBuilder {
    /// A custom RUM intake.
    let customIntakeURL: URL?

    /// The RUM view events filter from the payload.
    let eventsFilter: RUMViewEventsFilter

    /// The RUM request body format.
    let format = DataFormat(prefix: "", suffix: "", separator: "\n")

    /// Telemetry interface.
    let telemetry: Telemetry

    func request(
        for events: [Event],
        with context: AtatusContext,
        execution: ExecutionContext
    ) throws -> URLRequest {
        let filteredEvents = eventsFilter.filter(events: events)

        guard !filteredEvents.isEmpty else {
            throw InternalError(description: "All \(events.count) RUM events were filtered out, resulting in empty payload")
        }

        let data = format.format(filteredEvents.map { $0.data })

        let builder = URLRequestBuilder(
            url: url(with: context),
            // ATCHG: Added the Atatus identification query items (license key, agent name,
            // agent version, app name), matching `buildUrl()` in Android's `RumRequestFactory`.
            queryItems: [
                .atatusSource(source: context.source),
                .licenseKey(licenseKey: context.licenseKey),
                .agentName(agentName: AgentInfo.agentName),
                .agentVersion(agentVersion: AgentInfo.agentVersion),
                .appName(appName: context.appName ?? context.service)
            ] + execution.retryQueryItems,
            // ATCHG: End
            headers: [
                .contentTypeHeader(contentType: .textPlainUTF8),
                .userAgentHeader(
                    appName: context.applicationName,
                    appVersion: context.version,
                    device: context.device,
                    os: context.os
                ),
                .atAPIKeyHeader(licenseKey: context.licenseKey),
                .atEVPOriginHeader(source: context.ciAppOrigin ?? context.source),
                .atEVPOriginVersionHeader(sdkVersion: context.sdkVersion),
                .atRequestIDHeader(),
                .atIdempotencyKeyHeader(key: data.sha1())
            ],
            telemetry: telemetry
        )

        return builder.uploadRequest(with: data)
    }

    private func url(with context: AtatusContext) -> URL {
        // ATCHG: Atatus RUM intake path, matching `/v1/android/rum` in Android's `RumRequestFactory`.
        // Built from `intakeEndpoint` so a custom `serverUrl` is honoured, as on Android.
        customIntakeURL ?? context.intakeEndpoint.appendingPathComponent("v1/android/rum")
        // ATCHG: End
    }
}
