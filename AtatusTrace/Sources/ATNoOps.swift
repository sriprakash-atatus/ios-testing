/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; repointed the intake host at the
// Atatus site; rebranded the licence header.

import Foundation
import AtatusInternal
import OpenTelemetryApi

internal struct ATNoopGlobals {
    static let tracer = ATNoopTracer()
    static let span = ATNoopSpan()
    static let context = ATNoopSpanContext()
}

internal final class ATNoopTracer: OTTracer, OpenTelemetryApi.Tracer, Sendable {
    var activeSpan: OTSpan? { nil }

    private func warn() {
        AT.logger.warn(
            """
            The `AtatusTracer.shared()` was called but `AtatusTracer` is not initialised. Configure the `AtatusTracer` before invoking the feature:
                AtatusTracer.initialize()
            See https://www.atatus.com/docs/
            """
        )
    }

    func extract(reader: OTFormatReader) -> OTSpanContext? {
        warn()
        return ATNoopGlobals.context
    }

    func inject(spanContext: OTSpanContext, writer: OTFormatWriter) {
        warn()
    }

    func startSpan(operationName: String, references: [OTReference]?, tags: [String: OTTagValue]?, startTime: Date?) -> OTSpan {
        warn()
        return ATNoopGlobals.span
    }

    func startRootSpan(operationName: String, tags: [String: OTTagValue]?, startTime: Date?) -> OTSpan {
        warn()
        return ATNoopGlobals.span
    }

    func startRootSpan(operationName: String, tags: [String: any OTTagValue]?, startTime: Date?, customSampleRate: SampleRate?) -> any OTSpan {
        warn()
        return ATNoopGlobals.span
    }

    // MARK: - Open Telemetry

    func spanBuilder(spanName: String) -> OpenTelemetryApi.SpanBuilder {
        warn()
        return NOPOTelSpanBuilder()
    }
}

internal struct ATNoopSpan: OTSpan {
    var context: OTSpanContext { ATNoopGlobals.context }
    func tracer() -> OTTracer { ATNoopGlobals.tracer }
    func setOperationName(_ operationName: String) {}
    func finish(at time: Date) {}
    func log(fields: [String: Encodable & Sendable], timestamp: Date) {}
    func baggageItem(withKey key: String) -> String? { nil }
    func setBaggageItem(key: String, value: String) {}
    func setTag(key: String, value: OTTagValue) {}
    @discardableResult
    func setActive() -> OTSpan { self }
}

internal struct ATNoopSpanContext: OTSpanContext {
    func forEachBaggageItem(callback: (String, String) -> Bool) {}
}
