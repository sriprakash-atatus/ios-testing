/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

@testable import AtatusTrace

// MARK: - Span Mocks

public struct NOPSpanWriteContext: SpanWriteContext {
    public init() {}
    public func spanWriteContext(_ block: @escaping (AtatusContext, Writer) -> Void) {}
}

extension ATSpan {
    public static func mockAny(in core: AtatusCoreProtocol) -> ATSpan {
        return mockWith(core: core)
    }

    public static func mockWith(
        tracer: AtatusTracer,
        context: ATSpanContext = .mockAny(),
        operationName: String = .mockAny(),
        startTime: Date = .mockAny(),
        tags: [String: Encodable] = [:],
        eventBuilder: SpanEventBuilder = .mockAny(),
        eventWriter: SpanWriteContext = NOPSpanWriteContext()
    ) -> ATSpan {
        return ATSpan(
            tracer: tracer,
            context: context,
            operationName: operationName,
            startTime: startTime,
            tags: tags,
            eventBuilder: eventBuilder,
            eventWriter: eventWriter
        )
    }

    public static func mockWith(
        core: AtatusCoreProtocol,
        context: ATSpanContext = .mockAny(),
        operationName: String = .mockAny(),
        startTime: Date = .mockAny(),
        tags: [String: Encodable] = [:],
        eventBuilder: SpanEventBuilder = .mockAny(),
        eventWriter: SpanWriteContext = NOPSpanWriteContext()
    ) -> ATSpan {
        return ATSpan(
            tracer: .mockAny(in: core),
            context: context,
            operationName: operationName,
            startTime: startTime,
            tags: tags,
            eventBuilder: eventBuilder,
            eventWriter: eventWriter
        )
    }
}

extension ATSpanContext {
    public static func mockAny() -> ATSpanContext {
        return mockWith()
    }

    public static func mockWith(
        traceID: TraceID = .mockAny(),
        spanID: SpanID = .mockAny(),
        parentSpanID: SpanID? = .mockAny(),
        baggageItems: BaggageItems = .mockAny(),
        sampleRate: Float = .mockAny(),
        samplingDecision: SamplingDecision = .mockAny()
    ) -> ATSpanContext {
        return ATSpanContext(
            traceID: traceID,
            spanID: spanID,
            parentSpanID: parentSpanID,
            baggageItems: baggageItems,
            sampleRate: sampleRate,
            samplingDecision: samplingDecision
        )
    }
}

extension BaggageItems {
    public static func mockAny() -> BaggageItems {
        return BaggageItems()
    }
}

// MARK: - Component Mocks

extension AtatusTracer {
    public static func mockAny(in core: AtatusCoreProtocol) -> AtatusTracer {
        return mockWith(core: core)
    }

    public static func mockWith(
        core: AtatusCoreProtocol,
        samplingProvider: TracerSamplerProvider = TracerSamplerProviderMock.mockKeepAll(),
        tags: [String: Encodable] = [:],
        traceIDGenerator: TraceIDGenerator = DefaultTraceIDGenerator(),
        spanIDGenerator: SpanIDGenerator = DefaultSpanIDGenerator(),
        dateProvider: DateProvider = SystemDateProvider(),
        spanEventBuilder: SpanEventBuilder = .mockAny(),
        loggingIntegration: TracingWithLoggingIntegration = .mockAny()
    ) -> AtatusTracer {
        return AtatusTracer(
            core: core,
            samplingProvider: samplingProvider,
            tags: tags,
            traceIDGenerator: traceIDGenerator,
            spanIDGenerator: spanIDGenerator,
            dateProvider: dateProvider,
            loggingIntegration: loggingIntegration,
            spanEventBuilder: spanEventBuilder
        )
    }

    public static func mockWith(
        featureScope: FeatureScope,
        samplingProvider: TracerSamplerProvider = TracerSamplerProviderMock.mockKeepAll(),
        tags: [String: Encodable] = [:],
        traceIDGenerator: TraceIDGenerator = DefaultTraceIDGenerator(),
        spanIDGenerator: SpanIDGenerator = DefaultSpanIDGenerator(),
        dateProvider: DateProvider = SystemDateProvider(),
        spanEventBuilder: SpanEventBuilder = .mockAny(),
        loggingIntegration: TracingWithLoggingIntegration = .mockAny()
    ) -> AtatusTracer {
        return AtatusTracer(
            featureScope: featureScope,
            samplingProvider: samplingProvider,
            tags: tags,
            traceIDGenerator: traceIDGenerator,
            spanIDGenerator: spanIDGenerator,
            dateProvider: dateProvider,
            loggingIntegration: loggingIntegration,
            spanEventBuilder: spanEventBuilder
        )
    }
}

extension TracingWithLoggingIntegration {
    public static func mockAny() -> TracingWithLoggingIntegration {
        return TracingWithLoggingIntegration(
            core: NOPAtatusCore(),
            service: .mockAny(),
            networkInfoEnabled: .mockAny()
        )
    }
}

extension ContextMessageReceiver {
    public static func mockAny() -> ContextMessageReceiver {
        return ContextMessageReceiver(samplerProvider: SamplerProvider(sampleRate: .mockAny()))
    }
}

extension SpanEventBuilder {
    public static func mockAny() -> SpanEventBuilder {
        return mockWith()
    }

    public static func mockWith(
        service: String = .mockAny(),
        networkInfoEnabled: Bool = false,
        eventsMapper: SpanEventMapper? = nil,
        bundleWithRUM: Bool = false,
        telemetry: Telemetry = NOPTelemetry()
    ) -> SpanEventBuilder {
        let builder = SpanEventBuilder(
            service: service,
            networkInfoEnabled: networkInfoEnabled,
            eventsMapper: eventsMapper,
            bundleWithRUM: bundleWithRUM,
            telemetry: telemetry
        )
        builder.attributesEncoder.outputFormatting = [.sortedKeys] // to ensure stable order of JSON keys among OS versions
        return builder
    }
}

extension SpanEvent: AnyMockable, RandomMockable {
    public static func mockWith(
        traceID: TraceID = .mockAny(),
        spanID: SpanID = .mockAny(),
        parentID: SpanID? = .mockAny(),
        operationName: String = .mockAny(),
        serviceName: String = .mockAny(),
        resource: String = .mockAny(),
        startTime: Date = .mockAny(),
        duration: TimeInterval = .mockAny(),
        isError: Bool = .mockAny(),
        source: String = .mockAny(),
        origin: String? = nil,
        samplingRate: SampleRate = .maxSampleRate,
        samplingPriority: SamplingPriority = .mockAny(),
        samplingDecisionMaker: SamplingMechanismType = .mockAny(),
        tracerVersion: String = .mockAny(),
        applicationVersion: String = .mockAny(),
        networkConnectionInfo: NetworkConnectionInfo? = .mockAny(),
        mobileCarrierInfo: CarrierInfo? = .mockAny(),
        device: Device = .mockAny(),
        os: OperatingSystem = .mockAny(),
        userInfo: SpanEvent.UserInfo = .mockAny(),
        tags: [String: String] = [:]
    ) -> SpanEvent {
        return SpanEvent(
            traceID: traceID,
            spanID: spanID,
            parentID: parentID,
            operationName: operationName,
            serviceName: serviceName,
            resource: resource,
            startTime: startTime,
            duration: duration,
            isError: isError,
            source: source,
            origin: origin,
            samplingRate: samplingRate,
            samplingPriority: samplingPriority,
            samplingDecisionMaker: samplingDecisionMaker,
            tracerVersion: tracerVersion,
            applicationVersion: applicationVersion,
            networkConnectionInfo: networkConnectionInfo,
            mobileCarrierInfo: mobileCarrierInfo,
            device: device,
            os: os,
            userInfo: userInfo,
            tags: tags
        )
    }

    public static func mockAny() -> SpanEvent { .mockWith() }

    public static func mockRandom() -> SpanEvent {
        return SpanEvent(
            traceID: .mock(.mockRandom(), .mockRandom()),
            spanID: .mock(.mockRandom()),
            parentID: .mock(.mockRandom()),
            operationName: .mockRandom(),
            serviceName: .mockRandom(),
            resource: .mockRandom(),
            startTime: .mockRandomInThePast(),
            duration: .mockRandom(),
            isError: .random(),
            source: .mockRandom(),
            origin: .mockRandom(),
            samplingRate: .mockRandom(),
            samplingPriority: .mockRandom(),
            samplingDecisionMaker: .mockRandom(),
            tracerVersion: .mockRandom(),
            applicationVersion: .mockRandom(),
            networkConnectionInfo: .mockRandom(),
            mobileCarrierInfo: .mockRandom(),
            device: .mockRandom(),
            os: .mockRandom(),
            userInfo: .mockRandom(),
            tags: .mockRandom()
        )
    }
}

extension SpanEvent.UserInfo: AnyMockable, RandomMockable {
    public static func mockWith(
        id: String? = .mockAny(),
        name: String? = .mockAny(),
        email: String? = .mockAny(),
        extraInfo: [String: String] = [:]
    ) -> SpanEvent.UserInfo {
        return SpanEvent.UserInfo(
            id: id,
            name: name,
            email: email,
            extraInfo: extraInfo
        )
    }

    public static func mockAny() -> SpanEvent.UserInfo { .mockWith() }

    public static func mockRandom() -> SpanEvent.UserInfo {
        return SpanEvent.UserInfo(
            id: .mockRandom(),
            name: .mockRandom(),
            email: .mockRandom(),
            extraInfo: .mockRandom()
        )
    }
}

extension SpanEvent.AccountInfo: AnyMockable, RandomMockable {
    public static func mockWith(
        id: String = .mockAny(),
        name: String? = .mockAny(),
        extraInfo: [String: String] = [:]
    ) -> Self {
        return .init(
            id: id,
            name: name,
            extraInfo: extraInfo
        )
    }

    public static func mockAny() -> Self { .mockWith() }

    public static func mockRandom() -> Self {
        return .init(
            id: .mockRandom(),
            name: .mockRandom(),
            extraInfo: .mockRandom()
        )
    }
}

extension SamplingDecision: AnyMockable, RandomMockable {
    struct MockSampler: Sampling {
        let decision: Bool

        var samplingRate: SampleRate { 50 }

        func sample() -> Bool { decision }

        func combined(with childRate: SampleRate) -> SamplingDecision.MockSampler {
            self
        }
    }

    public static func mockAny() -> SamplingDecision {
        SamplingDecision(sampling: MockSampler(decision: false))
    }

    public static func mockRandom() -> AtatusTrace.SamplingDecision {
        let randomPriority = (-1...2).randomElement()

        switch randomPriority {
        case -1:
            let decision = SamplingDecision(sampling: MockSampler(decision: true))
            decision.addManualDropOverride()
            return decision
        case 0:
            return SamplingDecision(sampling: MockSampler(decision: false))
        case 1:
            return SamplingDecision(sampling: MockSampler(decision: true))
        case 2:
            let decision = SamplingDecision(sampling: MockSampler(decision: true))
            decision.addManualKeepOverride()
            return decision
        default:
            fatalError()
        }
    }

    public static func autoKept() -> SamplingDecision {
        SamplingDecision(sampling: MockSampler(decision: true))
    }
}

extension SamplingPriority: AnyMockable, RandomMockable {
    public static func mockAny() -> SamplingPriority {
        .autoKeep
    }

    public static func mockRandom() -> SamplingPriority {
        [SamplingPriority.manualDrop, .autoDrop, .autoKeep, .manualKeep].randomElement()!
    }
}

extension SamplingMechanismType: AnyMockable, RandomMockable {
    public static func mockAny() -> SamplingMechanismType {
        .agentRate
    }

    public static func mockRandom() -> SamplingMechanismType {
        [SamplingMechanismType.fallback, .agentRate, .manual].randomElement()!
    }
}

public struct MockActiveSpanProvider: TraceActiveSpanProvider {
    public init(storedActiveSpanContext: ActiveSpanContext?) {
        self.storedActiveSpanContext = storedActiveSpanContext
    }

    public let storedActiveSpanContext: ActiveSpanContext?

    public func activeSpanContext() -> ActiveSpanContext? {
        storedActiveSpanContext
    }
}

public struct TracerSamplerProviderMock: TracerSamplerProvider {
    public let sampler: any Sampling

    public init(sampler: any Sampling) {
        self.sampler = sampler
    }

    public func makeSamplerFor(samplingRate: SampleRate) -> any Sampling {
        Sampler(samplingRate: samplingRate)
    }

    public static func mockAny() -> TracerSamplerProvider {
        return TracerSamplerProviderMock(sampler: Sampler(samplingRate: 50))
    }

    public static func mockRandom() -> TracerSamplerProvider {
        return TracerSamplerProviderMock(sampler: Sampler(samplingRate: .random(in: (0.0...100.0))))
    }

    public static func mockKeepAll() -> TracerSamplerProvider {
        return TracerSamplerProviderMock(sampler: Sampler(samplingRate: 100))
    }

    public static func mockRejectAll() -> TracerSamplerProvider {
        return TracerSamplerProviderMock(sampler: Sampler(samplingRate: 0))
    }
}
