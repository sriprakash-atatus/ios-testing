/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import AtatusInternal

/// The Tracing URL Request Builder for formatting and configuring the `URLRequest`
/// to upload traces data.
internal struct TracingRequestBuilder: FeatureRequestBuilder {
    /// The tracing intake.
    let customIntakeURL: URL?

    /// The tracing request body format.
    let format = DataFormat(prefix: "", suffix: "", separator: "\n")

    /// Telemetry interface.
    let telemetry: Telemetry

    func request(
        for events: [Event],
        with context: AtatusContext,
        execution: ExecutionContext
    ) -> URLRequest {
        let builder = URLRequestBuilder(
            url: url(with: context),
            // ATCHG: Added the Atatus identification query items (source, license key, agent name,
            // agent version, app name), matching `create()` in Android's `TracesRequestFactory`.
            queryItems: [
                .atatusSource(source: context.source),
                .licenseKey(licenseKey: context.licenseKey),
                .agentName(agentName: AgentInfo.agentName),
                .agentVersion(agentVersion: AgentInfo.agentVersion),
                .appName(appName: context.appName ?? "")
            ],
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
                // ATCHG: Added the agent identification headers, matching `buildHeaders()` in
                // Android's `TracesRequestFactory`.
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

    func url(with context: AtatusContext) -> URL {
        // ATCHG: Atatus spans intake path, matching `/v1/android/spans` in Android's `TracesRequestFactory`.
        // ATCHG: Built from `intakeEndpoint` so a custom `serverUrl` is honoured, as on Android.
        customIntakeURL ?? context.intakeEndpoint.appendingPathComponent("v1/ios/spans")
        // ATCHG: End
        // ATCHG: End
    }
}
