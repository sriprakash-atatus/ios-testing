/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

internal struct WebViewRecordReceiver: FeatureMessageReceiver {
    internal struct WebRecord: Encodable {
        /// The RUM application ID of all records.
        let applicationID: String
        /// The RUM session ID of all records.
        let sessionID: String
        /// The RUM view ID of all records.
        let viewID: String
        /// Records enriched with further information.
        let records: [AnyEncodable]
    }

    /// Session Replay feature scope.
    let scope: FeatureScope

    func receive(message: AtatusInternal.FeatureMessage, from core: AtatusInternal.AtatusCoreProtocol) -> Bool {
        guard case let .webview(.record(event, view)) = message else {
            return false
        }

        scope.eventWriteContext { context, writer in
            // Extract the `RUMContext` or `nil` if RUM session is not sampled:
            guard
                let rumContext = context.additionalContext(ofType: RUMCoreContext.self),
                rumContext.sessionSampler.isSampled
            else {
                return
            }

            var event = event

            if let timestamp = event["timestamp"] as? Int,
               let webViewContext = context.additionalContext(ofType: RUMWebViewContext.self),
               let offset = webViewContext.serverTimeOffset(forView: view.id) {
                event["timestamp"] = Int64(timestamp) + offset.dd.toInt64Milliseconds
            }

            let record = WebRecord(
                applicationID: rumContext.applicationID,
                sessionID: rumContext.sessionID,
                viewID: view.id,
                records: [AnyEncodable(event)]
            )

            writer.write(value: record)
        }

        return true
    }
}
