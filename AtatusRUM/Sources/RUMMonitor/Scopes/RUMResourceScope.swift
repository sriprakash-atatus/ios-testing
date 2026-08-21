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

internal class RUMResourceScope: RUMScope {
    // MARK: - Initialization

    let parent: RUMContextProvider

    /// Container bundling dependencies for this scope.
    let dependencies: RUMScopeDependencies

    /// This Resource's UUID.
    let resourceUUID: RUMUUID
    /// The name used to identify this Resource.
    private let resourceKey: String
    /// Resource attributes.
    private var attributes: [AttributeKey: AttributeValue] = [:]

    /// The Resource url.
    private var resourceURL: String
    /// The start time of this Resource loading.
    private var resourceLoadingStartTime: Date

    /// Server time offset for date correction.
    ///
    /// The offset should be applied to event's timestamp for synchronizing
    /// local time with server time. This time interval value can be added to
    /// any date that needs to be synced. e.g:
    ///
    ///     date.addingTimeInterval(serverTimeOffset)
    private let serverTimeOffset: TimeInterval

    /// The HTTP method used to load this Resource.
    private var resourceHTTPMethod: RUMMethod
    /// Whether or not the Resource is provided by a first party host, if that information is available.
    private let isFirstPartyResource: Bool
    /// The Resource kind captured when starting the `URLRequest`.
    /// It may be `nil` if it's not possible to predict the kind from resource and the response MIME type is needed.
    private var resourceKindBasedOnRequest: RUMResourceType?

    /// The Resource metrics, if received. When sending RUM Resource event, `resourceMetrics` values
    /// take precedence over other values collected for this Resource.
    private var resourceMetrics: ResourceMetrics?

    /// Span context passed to the RUM backend in order to generate the APM span for underlying resource.
    private let spanContext: RUMSpanContext?

    /// The Time-to-Network-Settled metric for the view that tracks this resource.
    private let networkSettledMetric: TNSMetricTracking

    /// Callback called when a `RUMResourceEvent` is submitted for storage.
    private let onResourceEvent: (_ sent: Bool) -> Void
    /// Callback called when a `RUMErrorEvent` is submitted for storage.
    private let onErrorEvent: (_ sent: Bool) -> Void

    init(
        parent: RUMContextProvider,
        dependencies: RUMScopeDependencies,
        resourceKey: String,
        startTime: Date,
        serverTimeOffset: TimeInterval,
        url: String,
        httpMethod: RUMMethod,
        resourceKindBasedOnRequest: RUMResourceType?,
        spanContext: RUMSpanContext?,
        networkSettledMetric: TNSMetricTracking,
        onResourceEvent: @escaping (Bool) -> Void,
        onErrorEvent: @escaping (Bool) -> Void
    ) {
        self.parent = parent
        self.dependencies = dependencies
        self.resourceUUID = dependencies.rumUUIDGenerator.generateUnique()
        self.resourceKey = resourceKey
        self.resourceURL = url
        self.resourceLoadingStartTime = startTime
        self.serverTimeOffset = serverTimeOffset
        self.resourceHTTPMethod = httpMethod
        self.isFirstPartyResource = dependencies.firstPartyHosts?.isFirstParty(string: url) ?? false
        self.resourceKindBasedOnRequest = resourceKindBasedOnRequest
        self.spanContext = spanContext
        self.networkSettledMetric = networkSettledMetric
        self.onResourceEvent = onResourceEvent
        self.onErrorEvent = onErrorEvent

        // Track this resource in view's TNS metric:
        networkSettledMetric.trackResourceStart(at: startTime, resourceID: resourceUUID, resourceURL: url)
    }

    // MARK: - RUMScope

    func process(command: RUMCommand, context: AtatusContext, writer: Writer) -> Bool {
        self.attributes = self.attributes.merging(command.attributes, uniquingKeysWith: { $1 })

        switch command {
        case let command as RUMStopResourceCommand where command.resourceKey == resourceKey:
            sendResourceEvent(on: command, context: context, writer: writer)
            return false
        case let command as RUMStopResourceWithErrorCommand where command.resourceKey == resourceKey:
            sendErrorEvent(on: command, context: context, writer: writer)
            return false
        case let command as RUMAddResourceMetricsCommand where command.resourceKey == resourceKey:
            resourceMetrics = command.metrics
            networkSettledMetric.updateResource(with: command.metrics, resourceID: resourceUUID, resourceURL: resourceURL)
        default:
            break
        }
        return true
    }

    // MARK: - Sending RUM Events

    private func sendResourceEvent(on command: RUMStopResourceCommand, context: AtatusContext, writer: Writer) {
        let resourceStartTime: Date
        let resourceDuration: TimeInterval
        let size: Int64?

        // Trace context from cross-platform attributes or spanContext fallback
        let traceContext = extractTraceAttributes()

        // Span kind from cross-platform attributes, moved onto the canonical `span.kind` key
        promoteSpanKind()

        // GraphQL attributes from cross-platform attributes
        let graphql = extractGraphQL()

        // Extract captured HTTP headers
        let requestHeaders: [String: String]? = attributes.removeValue(forKey: CrossPlatformAttributes.requestHeaders)?.dd.decode()
        let responseHeaders: [String: String]? = attributes.removeValue(forKey: CrossPlatformAttributes.responseHeaders)?.dd.decode()
        let localCacheHit: Bool? = attributes.removeValue(forKey: CrossPlatformAttributes.localCacheHit)?.dd.decode() ?? resourceMetrics?.isLocalCacheHit

        // Metrics values take precedence over other values.
        if let metrics = resourceMetrics {
            resourceStartTime = metrics.fetch.start
            resourceDuration = metrics.fetch.end.timeIntervalSince(metrics.fetch.start)
            let metricsSize = metrics.responseBodySize?.decoded ?? 0
            size = metricsSize > 0 ? metricsSize : command.size
        } else {
            resourceStartTime = resourceLoadingStartTime
            resourceDuration = command.time.timeIntervalSince(resourceLoadingStartTime)
            size = command.size
        }

        // Resolved here rather than inline below: `context:` is passed before `resource:` in the event's
        // argument list and Swift evaluates arguments in source order, so an inline call would merge
        // `attributes` into `contextInfo` before the duration key was consumed, duplicating it as custom context.
        let reportedDuration = resolveReportedDuration(resourceDuration)

        let encodedBodySize = resourceMetrics?.responseBodySize?.encoded
        let decodedBodySize = resourceMetrics?.responseBodySize?.decoded

        let requestHeadersObj = requestHeaders.flatMap { $0.isEmpty ? nil : RUMResourceEvent.Resource.Request.Headers(headersInfo: $0) }
        let request: RUMResourceEvent.Resource.Request? = {
            let hasBodySize = resourceMetrics?.requestBodySize != nil
            let hasHeaders = requestHeadersObj != nil

            guard hasBodySize || hasHeaders else {
                return nil
            }

            return .init(
                decodedBodySize: resourceMetrics?.requestBodySize?.decoded,
                encodedBodySize: resourceMetrics?.requestBodySize?.encoded,
                headers: requestHeadersObj
            )
        }()

        let response: RUMResourceEvent.Resource.Response? = responseHeaders.flatMap { headers in
            headers.isEmpty ? nil : .init(headers: .init(headersInfo: headers))
        }

        // Write resource event
        let resourceEvent = RUMResourceEvent(
            dd: .init(
                browserSdkVersion: nil,
                configuration: .init(
                    sessionReplaySampleRate: nil,
                    sessionSampleRate: Double(dependencies.samplingRate)
                ),
                discarded: nil,
                parentSpanId: traceContext.parentSpanID?.toString(representation: .hexadecimal16Chars),
                rulePsr: traceContext.samplingRate,
                session: .init(
                    plan: .plan1,
                    sessionPrecondition: parent.context.sessionPrecondition
                ),
                spanId: traceContext.spanID?.toString(representation: .hexadecimal16Chars),
                traceId: traceContext.traceID?.toString(representation: .hexadecimal32Chars)
            ),
            account: .init(context: context),
            action: parent.context.activeUserActionID.map { rumUUID in
                .init(id: .string(value: rumUUID.toRUMDataFormat))
            },
            // ATCHG: application_id removed -- Atatus events do not carry a RUM application ID
            application: .init(id: ""),
            buildId: context.buildId,
            buildVersion: context.buildNumber,
            ciTest: dependencies.ciTest,
            connectivity: .init(context: context),
            container: nil,
            context: .init(contextInfo: command.globalAttributes.merging(parent.attributes) { $1 }.merging(attributes) { $1 }),
            date: resourceStartTime.addingTimeInterval(serverTimeOffset).timeIntervalSince1970.dd.toInt64Milliseconds,
            atatusTags: context.atTags,
            device: context.normalizedDevice(),
            display: nil,
            os: context.os,
            resource: .init(
                connect: resourceMetrics?.connect.map { metric in
                    .init(
                        duration: metric.duration.dd.toInt64Nanoseconds,
                        start: metric.start.timeIntervalSince(resourceStartTime).dd.toInt64Nanoseconds
                    )
                },
                decodedBodySize: decodedBodySize,
                deliveryType: nil,
                dns: resourceMetrics?.dns.map { metric in
                    .init(
                        duration: metric.duration.dd.toInt64Nanoseconds,
                        start: metric.start.timeIntervalSince(resourceStartTime).dd.toInt64Nanoseconds
                    )
                },
                download: resourceMetrics?.download.map { metric in
                    .init(
                        duration: metric.duration.dd.toInt64Nanoseconds,
                        start: metric.start.timeIntervalSince(resourceStartTime).dd.toInt64Nanoseconds
                    )
                },
                duration: reportedDuration,
                encodedBodySize: encodedBodySize,
                firstByte: resourceMetrics?.firstByte.map { metric in
                    .init(
                        duration: metric.duration.dd.toInt64Nanoseconds,
                        start: metric.start.timeIntervalSince(resourceStartTime).dd.toInt64Nanoseconds
                    )
                },
                graphql: graphql,
                id: resourceUUID.toRUMDataFormat,
                localCacheHit: localCacheHit,
                method: resourceHTTPMethod,
                protocol: nil,
                provider: resourceEventProvider,
                redirect: resourceMetrics?.redirection.map { metric in
                    .init(
                        duration: metric.duration.dd.toInt64Nanoseconds,
                        start: metric.start.timeIntervalSince(resourceStartTime).dd.toInt64Nanoseconds
                    )
                },
                renderBlockingStatus: nil,
                request: request,
                response: response,
                size: size ?? 0,
                ssl: resourceMetrics?.ssl.map { metric in
                    .init(
                        duration: metric.duration.dd.toInt64Nanoseconds,
                        start: metric.start.timeIntervalSince(resourceStartTime).dd.toInt64Nanoseconds
                    )
                },
                statusCode: command.httpStatusCode?.toInt64 ?? 0,
                transferSize: nil,
                type: resourceKindBasedOnRequest ?? command.kind,
                url: resourceURL,
                worker: nil
            ),
            service: context.service,
            session: .init(
                hasReplay: context.hasReplay,
                id: parent.context.sessionID.toRUMDataFormat,
                type: dependencies.sessionType
            ),
            source: .init(rawValue: context.source) ?? .ios,
            synthetics: dependencies.syntheticsTest,
            usr: .init(context: context),
            version: context.version,
            view: .init(
                id: parent.context.activeViewID.orNull.toRUMDataFormat,
                name: parent.context.activeViewName,
                referrer: nil,
                url: parent.context.activeViewPath ?? ""
            )
        )

        if let event = dependencies.eventBuilder.build(from: resourceEvent) {
            writer.write(value: event.withAgentInfo())
            onResourceEvent(true)
            networkSettledMetric.trackResourceEnd(
                at: resourceMetrics?.fetch.end ?? command.time,
                resourceID: resourceUUID,
                resourceDuration: resourceDuration
            )
        } else {
            onResourceEvent(false)
            networkSettledMetric.trackResourceDropped(resourceID: resourceUUID)
        }
    }

    private func sendErrorEvent(on command: RUMStopResourceWithErrorCommand, context: AtatusContext, writer: Writer) {
        let errorFingerprint: String? = attributes.removeValue(forKey: RUM.Attributes.errorFingerprint)?.dd.decode()
        // Never leak the internal cache-hit marker into arbitrary error context.
        attributes.removeValue(forKey: CrossPlatformAttributes.localCacheHit)
        let timeSinceAppStart = command.time.timeIntervalSince(context.launchInfo.processLaunchDate).dd.toInt64Milliseconds

        // Trace context from cross-platform attributes or spanContext fallback
        let traceContext = extractTraceAttributes()

        // Span kind from cross-platform attributes, moved onto the canonical `span.kind` key
        promoteSpanKind()

        // GraphQL attributes from cross-platform attributes
        let graphql = extractGraphQL()

        // Write error event
        let errorEvent = RUMErrorEvent(
            dd: .init(
                browserSdkVersion: nil,
                configuration: .init(sessionReplaySampleRate: nil, sessionSampleRate: Double(dependencies.samplingRate)),
                parentSpanId: traceContext.parentSpanID?.toString(representation: .hexadecimal16Chars),
                rulePsr: traceContext.samplingRate,
                session: .init(plan: .plan1, sessionPrecondition: parent.context.sessionPrecondition),
                spanId: traceContext.spanID?.toString(representation: .hexadecimal16Chars),
                traceId: traceContext.traceID?.toString(representation: .hexadecimal32Chars)
            ),
            account: .init(context: context),
            action: parent.context.activeUserActionID.map { rumUUID in
                .init(id: .string(value: rumUUID.toRUMDataFormat))
            },
            // ATCHG: application_id removed -- Atatus events do not carry a RUM application ID
            application: .init(id: ""),
            buildId: context.buildId,
            buildVersion: context.buildNumber,
            ciTest: dependencies.ciTest,
            connectivity: .init(context: context),
            container: nil,
            context: .init(contextInfo: command.globalAttributes.merging(parent.attributes) { $1 }.merging(attributes) { $1 }),
            date: command.time.addingTimeInterval(serverTimeOffset).timeIntervalSince1970.dd.toInt64Milliseconds,
            atatusTags: context.atTags,
            device: context.normalizedDevice(),
            display: nil,
            error: .init(
                binaryImages: nil,
                category: command.isNetworkError ? .network : .exception,
                csp: nil,
                fingerprint: errorFingerprint,
                handling: nil,
                handlingStack: nil,
                id: dependencies.rumUUIDGenerator.generateUnique().toRUMDataFormat,
                isCrash: false,
                message: command.errorMessage,
                meta: nil,
                resource: .init(
                    graphql: graphql,
                    method: resourceHTTPMethod,
                    provider: errorEventProvider,
                    statusCode: command.httpStatusCode?.toInt64 ?? 0,
                    url: resourceURL
                ),
                source: command.errorSource.toRUMDataFormat,
                sourceType: command.errorSourceType,
                stack: command.stack,
                threads: nil,
                timeSinceAppStart: timeSinceAppStart,
                type: command.errorType,
                wasTruncated: nil
            ),
            freeze: nil,
            os: context.os,
            service: context.service,
            session: .init(
                hasReplay: context.hasReplay,
                id: parent.context.sessionID.toRUMDataFormat,
                type: dependencies.sessionType
            ),
            source: .init(rawValue: context.source) ?? .ios,
            synthetics: dependencies.syntheticsTest,
            usr: .init(context: context),
            version: context.version,
            view: .init(
                id: parent.context.activeViewID.orNull.toRUMDataFormat,
                inForeground: nil,
                name: parent.context.activeViewName,
                referrer: nil,
                url: parent.context.activeViewPath ?? ""
            )
        )

        if let event = dependencies.eventBuilder.build(from: errorEvent) {
            writer.write(value: event.withAgentInfo())
            onErrorEvent(true)
            networkSettledMetric.trackResourceEnd(
                at: resourceMetrics?.fetch.end ?? command.time,
                resourceID: resourceUUID,
                resourceDuration: nil
            )
        } else {
            onErrorEvent(false)
            networkSettledMetric.trackResourceDropped(resourceID: resourceUUID)
        }
    }

    // MARK: - Resource provider helpers

    private var resourceEventProvider: RUMResourceEvent.Resource.Provider? {
        guard isFirstPartyResource == true else {
            return nil
        }

        return RUMResourceEvent.Resource.Provider(
            domain: providerDomain(from: resourceURL),
            name: nil,
            type: .firstParty
        )
    }

    private var errorEventProvider: RUMErrorEvent.Error.Resource.Provider? {
        guard isFirstPartyResource == true else {
            return nil
        }

        return RUMErrorEvent.Error.Resource.Provider(
            domain: providerDomain(from: resourceURL),
            name: nil,
            type: .firstParty
        )
    }

    private func providerDomain(from url: String) -> String? {
        return URL(string: url)?.host ?? url
    }

    private func resolveResourceDuration(_ duration: TimeInterval) -> Int64 {
        guard duration > 0.0 else {
            AT.logger.warn(
                """
                The computed duration for your resource: \(resourceURL) was 0 or negative. In order to keep the resource event we forced it to 1ns.
                """
            )
            return 1 // 1ns
        }

        return duration.dd.toInt64Nanoseconds
    }

    /// Decodes GraphQL errors JSON string into intermediate response error models.
    ///
    /// Note: The cross-platform attribute `_atatus.graphql.errors` contains a JSON array of error objects
    /// (e.g. `[{"message": "...", "locations": [...]}]`), not a full GraphQL response body.
    /// This is why we decode `[GraphQLResponseError]` directly rather than using the `GraphQLResponse`
    /// wrapper struct, which is used elsewhere for full response body parsing.
    private func decodeGraphQLResponseErrors(from jsonString: String?) -> [GraphQLResponseError]? {
        guard let jsonString, !jsonString.isEmpty else {
            return nil
        }
        guard let data = jsonString.data(using: .utf8) else {
            AT.logger.debug("Failed to convert GraphQL errors string to UTF-8 data")
            return nil
        }
        do {
            let errors = try JSONDecoder().decode([GraphQLResponseError].self, from: data)
            return errors.isEmpty ? nil : errors
        } catch {
            AT.logger.debug("Failed to decode GraphQL errors: \(error)")
            return nil
        }
    }

    // MARK: - Attribute extraction helpers

    /// Extracts trace attributes from `self.attributes`, consuming them via `removeValue`.
    /// Must be called at most once per event send — repeated calls return nil for consumed keys.
    private func extractTraceAttributes() -> (traceID: TraceID?, spanID: SpanID?, parentSpanID: SpanID?, samplingRate: Double?) {
        let rawTraceID: String? = attributes.removeValue(forKey: CrossPlatformAttributes.traceID)?.dd.decode()
        let rawSpanID: String? = attributes.removeValue(forKey: CrossPlatformAttributes.spanID)?.dd.decode()
        let rawParentSpanID: String? = attributes.removeValue(forKey: CrossPlatformAttributes.parentSpanID)?.dd.decode()
        let rawSamplingRate: Double? = attributes.removeValue(forKey: CrossPlatformAttributes.rulePSR)?.dd.decode()

        let traceID = rawTraceID.flatMap { TraceID($0, representation: .hexadecimal) } ?? spanContext?.traceID
        let spanID = rawSpanID.flatMap(RUMResourceScope.decodeCrossPlatformSpanID) ?? spanContext?.spanID

        // An all-zero id means "no parent" - it is what a cross-platform agent's id parser yields for an empty or
        // unparseable value. Promoting it would give a root span a parent that no span in the trace can satisfy.
        let parentSpanID = rawParentSpanID
            .flatMap(RUMResourceScope.decodeCrossPlatformSpanID)
            .flatMap { spanID -> SpanID? in spanID == SpanID.invalid ? nil : spanID }
            ?? spanContext?.parentSpanID

        return (traceID, spanID, parentSpanID, rawSamplingRate ?? spanContext?.samplingRate)
    }

    /// Reads a span id sent by a cross-platform SDK.
    ///
    /// Cross-platform agents report these ids the way `traceparent` carries them — 16 lower-case hex characters —
    /// because for those apps the RUM resource *is* the client span: no separate span payload is uploaded for it, so
    /// the id here has to string-match the id the receiving service records as its parent. Reading a hex id as decimal
    /// makes `UInt64.init` return nil for anything containing `a`-`f`, which dropped the id from the event entirely
    /// and left the trace waterfall with a missing client span.
    ///
    /// Decimal is still accepted as a fallback so agents predating that contract keep working. The two readings only
    /// disagree for ids made purely of the digits 0-9, where hex is the correct one for a current agent.
    private static func decodeCrossPlatformSpanID(_ string: String) -> SpanID? {
        SpanID(string, representation: .hexadecimal) ?? SpanID(string, representation: .decimal)
    }

    /// The flat tag name Atatus uses for a span's kind.
    ///
    /// Spelled out here rather than referenced from `AtatusTrace`'s `Tracer.Tags.kind`, which holds the same string:
    /// RUM does not link the Trace module, and an app can enable RUM without it.
    private static let spanKindTag = "span.kind"

    /// Re-publishes the cross-platform span kind on `self.attributes` under the flat `span.kind` key the rest of
    /// Atatus uses (`Tracer.Tags.kind` / `OTTags.spanKind`), so it reaches the event as the canonical kind instead of
    /// as an `_atatus.`-prefixed custom attribute. Without this the kind is never set and the span falls back to
    /// `server` in the trace view, even though every resource the agent reports is an outgoing `client` call.
    private func promoteSpanKind() {
        guard let spanKind: String = attributes.removeValue(forKey: CrossPlatformAttributes.spanKind)?.dd.decode() else {
            return
        }

        attributes[RUMResourceScope.spanKindTag] = spanKind
    }

    /// The duration to report for this resource, in nanoseconds.
    ///
    /// A cross-platform SDK observes the request on its own side of the platform channel, so it knows how long the
    /// request actually took; the duration measured here only covers the span between the two channel hops. When the
    /// SDK supplies its own measurement it wins. The attribute is consumed either way so it does not also surface as
    /// custom context.
    private func resolveReportedDuration(_ duration: TimeInterval) -> Int64 {
        guard let attribute = attributes.removeValue(forKey: CrossPlatformAttributes.resourceDuration) else {
            return resolveResourceDuration(duration)
        }

        // The platform channel picks the integer width from the value's magnitude, so a duration can arrive as any
        // of these. Checking one type only would silently discard the rest.
        var reported: Int64?
        if let value: Int64 = attribute.dd.decode() {
            reported = value
        } else if let value: Int = attribute.dd.decode() {
            reported = Int64(value)
        } else if let value: Int32 = attribute.dd.decode() {
            reported = Int64(value)
        } else if let value: UInt64 = attribute.dd.decode(), value <= UInt64(Int64.max) {
            reported = Int64(value)
        } else if let value: Double = attribute.dd.decode() {
            reported = Int64(value)
        }

        // A non-positive value is not a measurement - fall back rather than report it.
        if let reported = reported, reported > 0 {
            return reported
        }

        return resolveResourceDuration(duration)
    }

    /// Extracts GraphQL attributes from `self.attributes` and builds a `RUMGraphql` value.
    /// Consumes attributes via `removeValue` — must be called at most once per event send.
    /// Returns `nil` if no valid operation type is found.
    private func extractGraphQL() -> RUMGraphql? {
        let operationType: String? = attributes.removeValue(forKey: CrossPlatformAttributes.graphqlOperationType)?.dd.decode()
        let operationName: String? = attributes.removeValue(forKey: CrossPlatformAttributes.graphqlOperationName)?.dd.decode()
        let payload: String? = attributes.removeValue(forKey: CrossPlatformAttributes.graphqlPayload)?.dd.decode()
        let variables: String? = attributes.removeValue(forKey: CrossPlatformAttributes.graphqlVariables)?.dd.decode()
        let errorsJSON: String? = attributes.removeValue(forKey: CrossPlatformAttributes.graphqlErrors)?.dd.decode()

        guard
            let rawOperationType = operationType,
            let opType = RUMGraphql.OperationType(rawValue: rawOperationType)
        else {
            return nil
        }
        let errors = decodeGraphQLResponseErrors(from: errorsJSON)?.map { error in
            RUMGraphql.Errors(
                code: error.code,
                locations: error.locations?.map { .init(column: Int64($0.column), line: Int64($0.line)) },
                message: error.message,
                path: error.path?.map { pathElement in
                    switch pathElement {
                    case .string(let value): return .string(value: value)
                    case .int(let value): return .integer(value: Int64(value))
                    }
                }
            )
        }
        return .init(
            errorCount: errors?.count.toInt64,
            errors: errors,
            operationName: operationName,
            operationType: opType,
            payload: payload,
            variables: variables
        )
    }
}
