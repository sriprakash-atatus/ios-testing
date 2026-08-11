/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal
import OpenTelemetryApi

internal final class AtatusTracer: OTTracer, OpenTelemetryApi.Tracer {
    /// Trace feature scope.
    let featureScope: FeatureScope

    /// Global tags configured for Trace feature.
    let tags: [String: OTTagValue]
    /// Integration with Logging.
    let loggingIntegration: TracingWithLoggingIntegration

    let traceIDGenerator: TraceIDGenerator

    let spanIDGenerator: SpanIDGenerator

    /// Date provider for traces.
    let dateProvider: DateProvider

    let activeSpansPool = ActiveSpansPool()

    /// Provides a sampler used by spans created with tracer API.
    ///
    /// Refer to ``TracerSamplerProvider`` documentation for details on why using a dynamic
    /// sampler provider.
    let samplerProvider: TracerSamplerProvider

    /// Creates span events.
    let spanEventBuilder: SpanEventBuilder

    // MARK: - Initialization

    convenience init(
        core: AtatusCoreProtocol,
        samplingProvider: TracerSamplerProvider,
        tags: [String: OTTagValue],
        traceIDGenerator: TraceIDGenerator,
        spanIDGenerator: SpanIDGenerator,
        dateProvider: DateProvider,
        loggingIntegration: TracingWithLoggingIntegration,
        spanEventBuilder: SpanEventBuilder
    ) {
        self.init(
            featureScope: core.scope(for: TraceFeature.self),
            samplingProvider: samplingProvider,
            tags: tags,
            traceIDGenerator: traceIDGenerator,
            spanIDGenerator: spanIDGenerator,
            dateProvider: dateProvider,
            loggingIntegration: loggingIntegration,
            spanEventBuilder: spanEventBuilder
        )
    }

    init(
        featureScope: FeatureScope,
        samplingProvider: TracerSamplerProvider,
        tags: [String: OTTagValue],
        traceIDGenerator: TraceIDGenerator,
        spanIDGenerator: SpanIDGenerator,
        dateProvider: DateProvider,
        loggingIntegration: TracingWithLoggingIntegration,
        spanEventBuilder: SpanEventBuilder
    ) {
        self.featureScope = featureScope
        self.tags = tags
        self.traceIDGenerator = traceIDGenerator
        self.spanIDGenerator = spanIDGenerator
        self.dateProvider = dateProvider
        self.loggingIntegration = loggingIntegration
        self.samplerProvider = samplingProvider
        self.spanEventBuilder = spanEventBuilder
    }

    // MARK: - Open Tracing interface

    func startSpan(operationName: String, references: [OTReference]? = nil, tags: [String: OTTagValue]? = nil, startTime: Date? = nil) -> OTSpan {
        let parentSpanContext = references?.compactMap { $0.context.dd }.last ?? activeSpan?.context as? ATSpanContext
        return startSpan(
            spanContext: createSpanContext(parentSpanContext: parentSpanContext, using: samplerProvider.sampler),
            operationName: operationName,
            tags: tags,
            startTime: startTime
        )
    }

    func startRootSpan(operationName: String, tags: [String: OTTagValue]? = nil, startTime: Date? = nil, customSampleRate: SampleRate? = nil) -> OTSpan {
        let sampler: Sampling = if let customSampleRate {
            samplerProvider.makeSamplerFor(samplingRate: customSampleRate)
        } else {
            samplerProvider.sampler
        }

        return startSpan(
            spanContext: createSpanContext(parentSpanContext: nil, using: sampler),
            operationName: operationName,
            tags: tags,
            startTime: startTime
        )
    }

    func inject(spanContext: OTSpanContext, writer: OTFormatWriter) {
        writer.inject(spanContext: spanContext)
    }

    func extract(reader: OTFormatReader) -> OTSpanContext? {
        // TODO: RUMM-385 - make `HTTPHeadersReader` available in public API
        guard let context = reader.extract() as? ATSpanContext else {
            return nil
        }

        return ATSpanContext(
            traceID: context.traceID,
            spanID: context.spanID,
            parentSpanID: context.parentSpanID,
            baggageItems: context.baggageItems,
            sampleRate: samplerProvider.sampler.samplingRate,
            samplingDecision: context.samplingDecision
        )
    }

    var activeSpan: OTSpan? {
        return activeSpansPool.getActiveSpan()
    }

    // MARK: - Internal

    internal func createSpanContext(parentSpanContext: ATSpanContext?, using sampler: Sampling) -> ATSpanContext {
        ATSpanContext(
            traceID: parentSpanContext?.traceID ?? traceIDGenerator.generate(),
            spanID: spanIDGenerator.generate(),
            parentSpanID: parentSpanContext?.spanID,
            baggageItems: BaggageItems(parent: parentSpanContext?.baggageItems),
            sampleRate: parentSpanContext?.sampleRate ?? sampler.samplingRate,
            samplingDecision: parentSpanContext?.samplingDecision ?? SamplingDecision(sampling: sampler)
        )
    }

    internal func startSpan(spanContext: ATSpanContext, operationName: String, tags: [String: OTTagValue]? = nil, startTime: Date? = nil) -> OTSpan {
        var combinedTags = self.tags
        if let userTags = tags {
            combinedTags.merge(userTags) { $1 }
        }

        // Initialize `LazySpanWriteContext` here in `startSpan()` so it captures the `AtatusContext` valid
        // for this moment of time. Added in RUM-699 to ensure spans are correctly linked with RUM information
        // available on the caller thread.
        let writer = LazySpanWriteContext(featureScope: featureScope)
        let span = ATSpan(
            tracer: self,
            context: spanContext,
            operationName: operationName,
            startTime: startTime ?? dateProvider.now,
            tags: combinedTags,
            eventBuilder: spanEventBuilder,
            eventWriter: writer
        )
        return span
    }

    internal func addSpan(span: ATSpan, activityReference: ActivityReference) {
        activeSpansPool.addSpan(span: span, activityReference: activityReference)
        updateCoreAttributes()
    }

    internal func removeSpan(span: ATSpan) {
        activeSpansPool.removeSpan(span: span)
        updateCoreAttributes()
    }

    private func updateCoreAttributes() {
        let context = activeSpan?.context as? ATSpanContext

        featureScope.set(
            context: context.map {
                TraceCoreContext.Span(
                    traceID: String($0.traceID, representation: .hexadecimal),
                    spanID: String($0.spanID, representation: .decimal)
                )
            }
        )
    }
    // MARK: - OpenTelemetry

    func spanBuilder(spanName: String) -> OpenTelemetryApi.SpanBuilder {
        OTelSpanBuilder(
            active: false,
            attributes: [:],
            parent: .currentSpan,
            spanKind: .internal,
            spanName: spanName,
            startTime: nil,
            tracer: self
        )
    }
}
