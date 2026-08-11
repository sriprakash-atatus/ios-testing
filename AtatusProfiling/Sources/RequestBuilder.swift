/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `dd*` members to `at*`; renamed `clientToken` to `licenseKey`;
// rebranded the licence header.

import Foundation
import AtatusInternal

internal struct RequestBuilder: FeatureRequestBuilder {
    /// Builds multipart form for request's body.
    let multipartBuilder: MultipartFormDataBuilder

    /// Custom URL for uploading data to.
    let customUploadURL: URL?

    /// Sends telemetry through sdk core.
    let telemetry: Telemetry

    init(
        multipartBuilder: MultipartFormDataBuilder = MultipartFormData(),
        customUploadURL: URL? = nil,
        telemetry: Telemetry = NOPTelemetry()
    ) {
        self.multipartBuilder = multipartBuilder
        self.customUploadURL = customUploadURL
        self.telemetry = telemetry
    }

    func request(for events: [Event], with context: AtatusContext, execution: ExecutionContext) throws -> URLRequest {
        guard events.count == 1, let event = events.first else {
            throw ProgrammerError(description: "Invalid event count: \(events.count)")
        }

        guard let metadataData = event.metadata else {
            throw ProgrammerError(description: "Profile must include an event metadata")
        }

        let decoder = JSONDecoder()
        let attachments = try decoder.decode(ProfileAttachments.self, from: metadataData)

        var multipart = multipartBuilder

        multipart.addFormData(
            name: "event",
            filename: ProfileAttachments.Constants.profileEventFilename,
            data: event.data,
            mimeType: "application/json"
        )

        multipart.addFormData(
            name: ProfileAttachments.Constants.wallFilename,
            filename: ProfileAttachments.Constants.wallFilename,
            data: attachments.pprof,
            mimeType: "application/octet-stream"
        )

        if let rumEvents = attachments.rumEvents {
            multipart.addFormData(
                name: ProfileAttachments.Constants.rumEventsFilename,
                filename: ProfileAttachments.Constants.rumEventsFilename,
                data: rumEvents,
                mimeType: "application/json"
            )
        }

        let builder = URLRequestBuilder(
            url: url(with: context),
            queryItems: execution.retryQueryItems,
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

        return builder.uploadRequest(with: multipart.build(), compress: true)
    }

    private func url(with context: AtatusContext) -> URL {
        customUploadURL ?? context.site.endpoint.appendingPathComponent("api/v2/profile")
    }
}
