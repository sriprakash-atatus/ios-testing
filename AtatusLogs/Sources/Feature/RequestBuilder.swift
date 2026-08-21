/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import AtatusInternal

/// The Logging URL Request Builder for formatting and configuring the `URLRequest`
/// to upload logs data.
internal struct RequestBuilder: FeatureRequestBuilder {
    /// A custom logs intake.
    let customIntakeURL: URL?

    /// The logs request body format.
    let format = DataFormat(prefix: "[", suffix: "]", separator: ",")

    /// Telemetry interface.
    let telemetry: Telemetry

    init(
        customIntakeURL: URL? = nil,
        telemetry: Telemetry = NOPTelemetry()
    ) {
        self.customIntakeURL = customIntakeURL
        self.telemetry = telemetry
    }

    func request(
        for events: [Event],
        with context: AtatusContext,
        execution: ExecutionContext
    ) throws -> URLRequest {
        // ATCHG: Skip the batch while the logs heartbeat has not enabled logs, matching the
        // `if (!LogsHeartbeatScheduler.isLogsAllowed) return null` guard in Android's
        // `LogsRequestFactory.create`.
        guard LogsHeartbeatScheduler.isLogsAllowed else {
            throw LogsDisabledByHeartbeatError()
        }
        // ATCHG: End

        let builder = URLRequestBuilder(
            url: url(with: context),
            // ATCHG: Added the Atatus identification query items (license key, agent name,
            // agent version, app name), matching `buildUrl()` in Android's `LogsRequestFactory`.
            queryItems: [
                .atatusSource(source: context.source),
                .licenseKey(licenseKey: context.licenseKey),
                .agentName(agentName: AgentInfo.agentName),
                .agentVersion(agentVersion: AgentInfo.agentVersion),
                .appName(appName: context.appName ?? "")
            ],
            // ATCHG: End
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
                .atRequestIDHeader(),
                // ATCHG: Added the agent identification headers, matching `buildHeaders()` in
                // Android's `LogsRequestFactory`.
                .atatusAgentNameHeader(),
                .atatusAgentVersionHeader(),
                .atatusAppNameHeader(appName: context.appName ?? "")
                // ATCHG: End
            ],
            telemetry: telemetry
        )

        let data = format.format(events.map { $0.data })
        return builder.uploadRequest(with: data)
    }

    private func url(with context: AtatusContext) -> URL {
        // ATCHG: Atatus logs intake path, matching `/v1/android/logs` in Android's `LogsRequestFactory`.
        // ATCHG: Built from `intakeEndpoint` so a custom `serverUrl` is honoured, as on Android.
        customIntakeURL ?? context.intakeEndpoint.appendingPathComponent("v1/android/logs")
        // ATCHG: End
        // ATCHG: End
    }
}

// ATCHG: Signals that the logs heartbeat has not (yet) enabled log uploads. Thrown instead of
// returning `nil`, which is how Android's `LogsRequestFactory.create` skips the batch.
internal struct LogsDisabledByHeartbeatError: Error, CustomStringConvertible {
    let description = "Logs upload skipped: the Atatus logs heartbeat has not enabled logs."
}
// ATCHG: End
