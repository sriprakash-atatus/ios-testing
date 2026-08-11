/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`;
// rebranded the licence header.

import Foundation
import AtatusInternal

internal final class ATSpan: OTSpan, @unchecked Sendable {
    /// The `Tracer` which created this span.
    private let atTracer: AtatusTracer
    /// Span context.
    internal let atContext: ATSpanContext
    /// Span creation date
    internal let startTime: Date
    /// Writes span logs to Logging Feature. `nil` if Logging feature is disabled.
    private let loggingIntegration: TracingWithLoggingIntegration

    /// Span operation name.
    @ReadWriteLock
    private var operationName: String
    /// Span tags.
    @ReadWriteLock
    private var tags: [String: OTTagValue]
    /// Span log fields.
    @ReadWriteLock
    private var logFields: [[String: Encodable & Sendable]]
    /// If this span has completed.
    @ReadWriteLock
    private var isFinished: Bool
    @ReadWriteLock
    private var activityReference: ActivityReference?
    /// Builds span events.
    private let eventBuilder: SpanEventBuilder
    /// Writes span events to core.
    private let eventWriter: SpanWriteContext

    init(
        tracer: AtatusTracer,
        context: ATSpanContext,
        operationName: String,
        startTime: Date,
        tags: [String: OTTagValue],
        eventBuilder: SpanEventBuilder,
        eventWriter: SpanWriteContext
    ) {
        self.atTracer = tracer
        self.atContext = context
        self.startTime = startTime
        self.loggingIntegration = tracer.loggingIntegration
        self.operationName = operationName
        self.tags = tags
        self.logFields = []
        self.isFinished = false
        self.eventBuilder = eventBuilder
        self.eventWriter = eventWriter
    }

    // MARK: - Open Tracing interface

    var context: OTSpanContext {
        return atContext
    }

    func tracer() -> OTTracer {
        return atTracer
    }

    func setOperationName(_ operationName: String) {
        if warnIfFinished("setOperationName(_:)") {
            return
        }
        self.operationName = operationName
    }

    func setTag(key: String, value: OTTagValue) {
        if warnIfFinished("setTag(key:value:)") {
            return
        }

        if atContext.span(self, willSetTagWithKey: key, value: value) {
            _tags.mutate { $0[key] = value }
        }
    }

    func setBaggageItem(key: String, value: String) {
        if warnIfFinished("setBaggageItem(key:value:)") {
            return
        }
        atContext.baggageItems.set(key: key, value: value)
    }

    func baggageItem(withKey key: String) -> String? {
        if warnIfFinished("baggageItem(withKey:)") {
            return nil
        }
        return atContext.baggageItems.get(key: key)
    }

    @discardableResult
    func setActive() -> OTSpan {
        activityReference = ActivityReference()
        if let activityReference = activityReference {
            atTracer.addSpan(span: self, activityReference: activityReference)
        }
        return self
    }

    func log(fields: [String: Encodable & Sendable], timestamp: Date) {
        log(message: nil, fields: fields, timestamp: timestamp)
    }

    func log(message: String?, fields: [String: Encodable & Sendable], timestamp: Date) {
        if warnIfFinished("log(fields:timestamp:)") {
            return
        }
        logFields.append(fields)
        sendSpanLogs(message: message, fields: fields, date: timestamp)
    }

    func finish(at time: Date) {
        var shouldRun = true
        _isFinished.mutate {
            if warnIfFinished("finish(at:)", isFinished: $0) {
                shouldRun = false
                return
            }
            $0 = true
        }
        if !shouldRun {
            return
        }

        if let activity = activityReference {
            atTracer.removeSpan(span: self)
            activity.leave()
        }
        if self.atContext.samplingDecision.samplingPriority.isKept {
            sendSpan(finishTime: time)
        }
    }

    // MARK: - Writing SpanEvent

    /// Sends span event for given `ATSpan`.
    private func sendSpan(finishTime: Date) {
        eventWriter.spanWriteContext { context, writer in
            let event = self.eventBuilder.createSpanEvent(
                context: context,
                traceID: self.atContext.traceID,
                spanID: self.atContext.spanID,
                parentSpanID: self.atContext.parentSpanID,
                operationName: self.operationName,
                startTime: self.startTime,
                finishTime: finishTime,
                samplingRate: self.atContext.sampleRate / 100.0,
                samplingPriority: self.atContext.samplingDecision.samplingPriority,
                samplingDecisionMaker: self.atContext.samplingDecision.decisionMaker,
                tags: self.tags,
                baggageItems: self.atContext.baggageItems.all,
                logFields: self.logFields
            )

            let envelope = SpanEventsEnvelope(span: event, environment: context.env)
            // ATCHG: Append the `agent` object to the spans envelope, matching
            // `SpanEventSerializer.serialize()` in the Atatus Android agent.
            writer.write(value: envelope.withAgentInfo())
            // ATCHG: End
        }
    }

    private func sendSpanLogs(message: String?, fields: [String: Encodable], date: Date) {
        loggingIntegration.writeLog(withSpanContext: atContext, message: message, fields: fields, date: date, else: {
            AT.logger.warn("The log for span \"\(self.operationName)\" will not be send, because the Logs feature is not enabled.")
        })
    }

    // MARK: - Private

    private func warnIfFinished(_ methodName: String) -> Bool {
        warnIfFinished(methodName, isFinished: isFinished)
    }

    private func warnIfFinished(_ methodName: String, isFinished: Bool) -> Bool {
        return warn(
            if: isFinished,
            message: "🔥 Calling `\(methodName)` on a finished span (\"\(operationName)\") is not allowed."
        )
    }
}
