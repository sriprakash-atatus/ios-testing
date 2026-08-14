/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `dd*` members to `at*`; renamed `clientToken` to `licenseKey`;
// rebranded the licence header.

#if os(iOS)
import Foundation
import AtatusInternal

internal struct ResourceRequestBuilder: FeatureRequestBuilder {
    /// Custom URL for uploading data to.
    let customUploadURL: URL?
    /// Sends telemetry through sdk core.
    let telemetry: Telemetry
    /// Builds multipart form for request's body.
    let multipartBuilder: MultipartFormDataBuilder

    init(
        customUploadURL: URL?,
        telemetry: Telemetry,
        multipartBuilder: MultipartFormDataBuilder = MultipartFormData()
    ) {
        self.customUploadURL = customUploadURL
        self.telemetry = telemetry
        self.multipartBuilder = multipartBuilder
    }

    func request(
        for events: [Event],
        with context: AtatusContext,
        execution: ExecutionContext
    ) throws -> URLRequest {
        let decoder = JSONDecoder()
        let resources = try events.map { event in
            try decoder.decode(EnrichedResource.self, from: event.data)
        }
        return try createRequest(resources: resources, context: context, execution: execution)
    }

    private func createRequest(resources: [EnrichedResource], context: AtatusContext, execution: ExecutionContext) throws -> URLRequest {
        var multipart = multipartBuilder

        let builder = URLRequestBuilder(
            url: url(with: context),
            // ATCHG: Added the Atatus identification query items, matching AtatusRUM's and
            // AtatusLogs' `RequestBuilder`.
            queryItems: atatusIdentificationQueryItems(with: context) + execution.retryQueryItems,
            // ATCHG: End
            headers: [
                .contentTypeHeader(contentType: .multipartFormData(boundary: multipart.boundary)),
                .userAgentHeader(
                    appName: context.applicationName,
                    appVersion: context.version,
                    device: context.device,
                    os: context.os
                ),
                .atAPIKeyHeader(licenseKey: context.licenseKey),
                .atEVPOriginHeader(source: context.source),
                .atEVPOriginVersionHeader(sdkVersion: context.sdkVersion),
                .atRequestIDHeader(),
            ],
            telemetry: telemetry
        )

        resources.forEach {
            multipart.addFormData(
                name: "image",
                filename: $0.identifier,
                data: $0.data,
                mimeType: $0.mimeType
            )
        }
        if let context = resources.first?.context {
            let data = try JSONEncoder().encode(context)
            multipart.addFormData(
                name: "event",
                filename: "blob",
                data: data,
                mimeType: "application/json"
            )
        }

        return builder.uploadRequest(with: multipart.build(), compress: true)
    }

    private func url(with context: AtatusContext) -> URL {
        // ATCHG: Atatus Session Replay intake path, matching `v1/ios/rum` in AtatusRUM. Built from
        // `intakeEndpoint` so a custom `serverUrl` is honoured, as on Android.
        customUploadURL ?? context.intakeEndpoint.appendingPathComponent(atatusSessionReplayIntakePath)
        // ATCHG: End
    }
}
#endif
