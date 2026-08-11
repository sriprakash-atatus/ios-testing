/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

/// Errors that can be thrown when parsing a WebView message
internal enum WebViewMessageError: Error, Equatable {
    case dataSerialization(message: String)
    case invalidMessage(description: String)
}

/// A type forwarding type-less messages received from Atatus Browser SDK to either `AtatusRUM` or `AtatusLogs`.
internal final class MessageEmitter: InternalExtension<WebViewTracking>.AbstractMessageEmitter {
    /// The core for events forwarding.
    private weak var core: AtatusCoreProtocol?
    /// Log events sampler.
    let logsSampler: Sampler

    init(
        logsSampler: Sampler,
        core: AtatusCoreProtocol
    ) {
        self.logsSampler = logsSampler
        self.core = core
    }

    /// Sends a bag of data to the message bus
    /// - Parameter body: The data to send, it must be parsable to `WebViewMessage`
    override func send(body: Any, slotId: String? = nil) {
        guard let core = core else {
            return AT.logger.debug("Core must not be nil when using WebViewTracking")
        }

        do {
            guard let body = body as? String else {
                throw WebViewMessageError.invalidMessage(description: String(describing: body))
            }

            guard let data = body.data(using: .utf8) else {
                throw WebViewMessageError.dataSerialization(message: body)
            }

            let decoder = JSONDecoder()
            let message = try decoder.decode(WebViewMessage.self, from: data)

            switch message {
            case .log:
                send(log: message, in: core)
            case .rum, .telemetry:
                send(rum: message, in: core)
            case let .record(event, view):
                send(record: event, view: view, slotId: slotId, in: core)
            }
        } catch {
            AT.logger.error("Encountered an error when receiving web view event", error: error)
            core.telemetry.error("Encountered an error when receiving web view event", error: error)
        }
    }

    private func send(log message: WebViewMessage, in core: AtatusCoreProtocol) {
        guard logsSampler.sample() else {
            return
        }

        core.send(message: .webview(message), else: {
            AT.logger.warn("A WebView log is lost because Logging is disabled in the SDK")
        })
    }

    private func send(rum message: WebViewMessage, in core: AtatusCoreProtocol) {
        core.send(message: .webview(message), else: {
            AT.logger.warn("A WebView RUM event is lost because RUM is disabled in the SDK")
        })
    }

    private func send(record event: WebViewMessage.Event, view: WebViewMessage.View, slotId: String?, in core: AtatusCoreProtocol) {
        var event = event
        // inject the slotId
        event["slotId"] = slotId

        core.send(message: .webview(.record(event, view)), else: {
            AT.logger.warn("A WebView Replay record is lost because Session Replay is disabled in the SDK")
        })
    }
}
