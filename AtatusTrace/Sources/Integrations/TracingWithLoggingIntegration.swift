/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; renamed `dd.trace_id` /
// `dd.span_id` to `atatus.trace_id` / `atatus.span_id`; rebranded the licence header.

import Foundation
@preconcurrency import AtatusInternal

/// Integration between Tracing and Logging Features to allow sending logs for spans (`span.log(fields:timestamp:)`)
internal struct TracingWithLoggingIntegration: Sendable {
    private struct Constants {
        static let defaultLogMessage = "Span event"
        static let defaultErrorProperty = "Unknown"
        /// Key referencing the trace ID.
        static let traceIDKey = "atatus.trace_id"
        /// Key referencing the span ID.
        static let spanIDKey = "atatus.span_id"
    }

    /// `AtatusCore` instance managing this integration.
    weak var core: AtatusCoreProtocol?
    let service: String?
    let networkInfoEnabled: Bool

    init(core: AtatusCoreProtocol, service: String?, networkInfoEnabled: Bool) {
        self.core = core
        self.service = service
        self.networkInfoEnabled = networkInfoEnabled
    }

    // swiftlint:disable function_default_parameter_at_end
    func writeLog(
        withSpanContext spanContext: ATSpanContext,
        message: String? = nil,
        fields: [String: Encodable],
        date: Date,
        else fallback: @escaping () -> Void
    ) {
        guard let core = core else {
            return
        }

        var userAttributes = fields

        // get the log message and optional error kind
        let errorKind: String? = userAttributes.removeValue(forKey: OTLogFields.errorKind)?.dd.decode()
        let message = userAttributes.removeValue(forKey: OTLogFields.message)?.dd.decode() ?? message ?? Constants.defaultLogMessage
        let errorStack: String? = userAttributes.removeValue(forKey: OTLogFields.stack)?.dd.decode()

        // infer the log level
        let isErrorEvent = fields[OTLogFields.event] as? String == "error"
        let hasErrorKind = errorKind != nil
        let level: LogMessage.Level = (isErrorEvent || hasErrorKind) ? .error : .info

        let extractedError: ATError? = level == .error ?
            ATError(
                type: errorKind ?? Constants.defaultErrorProperty,
                message: message,
                stack: errorStack ?? Constants.defaultErrorProperty
            )
        : nil

        core.send(
            message: .payload(
                LogMessage(
                    logger: "trace",
                    service: service,
                    date: date,
                    message: message,
                    error: extractedError,
                    level: level,
                    thread: Thread.current.dd.name,
                    networkInfoEnabled: networkInfoEnabled,
                    userAttributes: userAttributes,
                    internalAttributes: [
                        Constants.traceIDKey: String(spanContext.traceID, representation: .hexadecimal),
                        Constants.spanIDKey: String(spanContext.spanID, representation: .hexadecimal)
                    ]
                )
            ),
            else: fallback
        )
    }
    // swiftlint:enable function_default_parameter_at_end
}
