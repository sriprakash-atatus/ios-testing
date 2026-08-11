/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`;
// renamed the `_dd` attribute prefix to `_atatus`; renamed the `ddsource` / `ddtags` query parameters to
// `atatus_source` / `atatustags`; rebranded the licence header.

import Foundation
import AtatusInternal

internal typealias JSON = [String: Any]

/// Receiver to consume a RUM event coming from Browser SDK.
internal final class WebViewEventReceiver: FeatureMessageReceiver {
    /// RUM feature scope.
    let featureScope: FeatureScope
    /// Subscriber that can process a `RUMKeepSessionAliveCommand`.
    let commandSubscriber: RUMCommandSubscriber

    /// The date provider.
    let dateProvider: DateProvider

    /// The view cache containing ids of current and previous views.
    let viewCache: ViewCache

    /// Creates a new receiver.
    ///
    /// - Parameters:
    ///   - featureScope: The feature scope.
    ///   - dateProvider: The date provider.
    ///   - commandSubscriber: Subscriber that can process a `RUMKeepSessionAliveCommand`.
    ///   - viewCache: The RUM view cache.
    init(
        featureScope: FeatureScope,
        dateProvider: DateProvider,
        commandSubscriber: RUMCommandSubscriber,
        viewCache: ViewCache
    ) {
        self.featureScope = featureScope
        self.commandSubscriber = commandSubscriber
        self.dateProvider = dateProvider
        self.viewCache = viewCache
    }

    /// Writes a Browser RUM event to the core.
    ///
    /// The receiver will inject current RUM context and apply server-time offset to the event.
    ///
    /// - Parameters:
    ///   - message: The message containing the Browser RUM event.
    ///   - core: The core to write the event.
    func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        switch message {
        case let .webview(.rum(event)):
            receive(rum: event, core: core)
        case let .webview(.telemetry(event)):
            receive(telemetry: event)
        default:
            return false
        }

        return true
    }

    private func receive(rum event: JSON, core: AtatusCoreProtocol) {
        commandSubscriber.process(
            command: RUMKeepSessionAliveCommand(
                time: dateProvider.now,
                attributes: [:]
            )
        )

        featureScope.eventWriteContext { context, writer in
            guard let rum = context.additionalContext(ofType: RUMCoreContext.self), rum.sessionSampler.isSampled else {
                return // Drop event if RUM is not enabled or RUM session is not sampled
            }

            var webViewContext = context.additionalContext(ofType: RUMWebViewContext.self) ?? .init()
            var event = event

            event["atatusTags"] = ATTag.merge(context.atTags, with: event["atatusTags"] as? String)

            if let date = event["date"] as? Int,
               let view = event["view"] as? JSON,
               let id = view["id"] as? String {
                let offsetMilliseconds: Int64

                if let offset = webViewContext.serverTimeOffset(forView: id) {
                    offsetMilliseconds = offset.dd.toInt64Milliseconds
                } else {
                    let offset = context.serverTimeOffset
                    webViewContext.setServerTimeOffset(offset, forView: id)

                    self.featureScope.set(context: webViewContext)
                    offsetMilliseconds = offset.dd.toInt64Milliseconds
                }

                let correctedDate = Int64(date) + offsetMilliseconds
                event["date"] = correctedDate

                // Inject the container source and view id
                if let viewID = self.viewCache.lastView(before: correctedDate, hasReplay: true) {
                    event[RUMViewEvent.CodingKeys.container.rawValue] = RUMViewEvent.Container(
                        source: RUMViewEvent.Container.Source(rawValue: context.source) ?? .ios,
                        view: RUMViewEvent.Container.View(id: viewID)
                    )
                }
            }

            if var application = event["application"] as? JSON {
                application["id"] = rum.applicationID
                event["application"] = application
            }

            if var session = event["session"] as? JSON {
                session["id"] = rum.sessionID
                // Unset `has_replay` if native replay is disabled
                if context.hasReplay != true {
                    session["has_replay"] = context.hasReplay
                }

                event["session"] = session
            }

            if var dd = event["_atatus"] as? JSON {
                if context.hasReplay != true {
                    // Remove stats if native replay is disabled
                    dd["replay_stats"] = nil
                    event["_atatus"] = dd
                }
                if dd["rule_psr"] != nil,
                   let networkInstrumentation = core.feature(
                    named: Feature.networkInstrumentation,
                    type: DistributedTracingSampleRateProvider.self
                   ),
                   let distributedTracingSampleRate = networkInstrumentation.distributedTracingSampleRate {
                    dd["rule_psr"] = distributedTracingSampleRate.percentageProportion
                    event["_atatus"] = dd
                }
            }

            // Add native anonymous_id to the event's usr object
            if let anonymousId = context.userInfo?.anonymousId {
                var usr = event["usr"] as? JSON ?? [:]
                usr["anonymous_id"] = anonymousId
                event["usr"] = usr
            }

            writer.write(value: AnyEncodable(event))
        }
    }

    private func receive(telemetry event: JSON) {
        // RUM-2866: Update with dedicated telemetry track
        featureScope.eventWriteContext { context, writer in
            guard let rum = context.additionalContext(ofType: RUMCoreContext.self), rum.sessionSampler.isSampled else {
                return // Drop event if RUM is not enabled or RUM session is not sampled
            }

            var event = event

            if let date = event["date"] as? Int {
                event["date"] = Int64(date) + context.serverTimeOffset.dd.toInt64Milliseconds
            }

            if var application = event["application"] as? JSON {
                application["id"] = rum.applicationID
                event["application"] = application
            }

            if var session = event["session"] as? JSON {
                session["id"] = rum.sessionID
                event["session"] = session
            }

            writer.write(value: AnyEncodable(event))
        }
    }
}
