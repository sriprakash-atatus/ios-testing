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

internal struct SegmentRequestBuilder: FeatureRequestBuilder {
    private static let newlineByte = "\n".data(using: .utf8)! // swiftlint:disable:this force_unwrapping

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
        guard !events.isEmpty else {
            throw InternalError(description: "[SR] batch events must not be empty.")
        }

        let source = SRSegment.Source(rawValue: context.source) ?? {
            telemetry.error("[SR] Could not create segment source from provided string '\(context.source)'")
            return .ios
        }()

        // If we can't decode `events: [Data]` there is no way to recover, so we throw an
        // error to let the core delete the batch:
        let segments = try events
            .map { try SegmentJSON($0.data, source: source) }
            .merge()

        return try createRequest(segments: segments, context: context, execution: execution)
    }

    private func createRequest(segments: [SegmentJSON], context: AtatusContext, execution: ExecutionContext) throws -> URLRequest {
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

        let metadata = try segments.enumerated().map { index, segment in
            var json = segment.toJSONObject()
            // Session Replay BE accepts compressed segment data followed by newline character (before compression):
            let data = try JSONSerialization.data(withJSONObject: json) + SegmentRequestBuilder.newlineByte
            let compressedData = try SRCompression.compress(data: data)
            // Compressed segment is sent within multipart form data - with some of segment (metadata)
            // attributes listed as form fields:
            multipart.addFormData(
                name: "segment",
                filename: "file\(index)",
                data: compressedData,
                mimeType: "application/octet-stream"
            )
            // Remove the 'records' for the metadata
            json["records"] = nil
            json["raw_segment_size"] = data.count
            json["compressed_segment_size"] = compressedData.count
            return json
        }

        let data = try JSONSerialization.data(withJSONObject: metadata)
        multipart.addFormData(
            name: "event",
            filename: "blob",
            data: data,
            mimeType: "application/json"
        )

        // Data is already compressed, so request building request w/o compression:
        return builder.uploadRequest(with: multipart.build(), compress: false)
    }

    private func url(with context: AtatusContext) -> URL {
        // ATCHG: Atatus Session Replay intake path, matching `v1/ios/rum` in AtatusRUM. Built from
        // `intakeEndpoint` so a custom `serverUrl` is honoured, as on Android.
        customUploadURL ?? context.intakeEndpoint.appendingPathComponent(atatusSessionReplayIntakePath)
        // ATCHG: End
    }
}

// ATCHG: Session Replay uploads carry the same identification query items that AtatusRUM's and
// AtatusLogs' `RequestBuilder`s add (Android: `RumRequestFactory.buildUrl` /
// `LogsRequestFactory.buildUrl`), so RUM, Logs and Session Replay all reach the intake with the
// same URL parameters. Shared with `ResourceRequestBuilder`; declared here rather than in its own
// file because `Atatus.xcodeproj` references Session Replay sources individually.
internal func atatusIdentificationQueryItems(
    with context: AtatusContext
) -> [URLRequestBuilder.QueryItem] {
    return [
        .atatusSource(source: context.source),
        .licenseKey(licenseKey: context.licenseKey),
        .agentName(agentName: AgentInfo.agentName),
        .agentVersion(agentVersion: AgentInfo.agentVersion),
        .appName(appName: context.appName ?? context.service)
    ]
}

/// Atatus Session Replay intake path, matching `v1/android/rum` in AtatusRUM and
/// `v1/android/logs` in AtatusLogs.
///
/// On `v1/android/*` for the same reason as those: the intake serves only the Android paths and
/// answers 401 on `v1/ios/replay`. Revert alongside them once the backend serves the iOS paths.
internal let atatusSessionReplayIntakePath = "v1/android/replay"
// ATCHG: End

#endif
