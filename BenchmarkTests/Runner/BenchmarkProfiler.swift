/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddBenchmarks` -> `AtatusBenchmarks`,
// `ddInternal` -> `AtatusInternal`; rebranded the licence header.

import Foundation
import AtatusInternal
import AtatusBenchmarks
import OpenTelemetryApi

internal final class Profiler: AtatusInternal.BenchmarkProfiler {
    let provider: TracerProvider

    init(provider: TracerProvider) {
        self.provider = provider
    }

    func tracer(operation: @autoclosure () -> String) -> any AtatusInternal.BenchmarkTracer {
        TracerWrapper(
            tracer: provider.get(
                instrumentationName: operation(),
                instrumentationVersion: nil
            )
        )
    }
}

private final class TracerWrapper: AtatusInternal.BenchmarkTracer {
    let tracer: OpenTelemetryApi.Tracer

    init(tracer: OpenTelemetryApi.Tracer) {
        self.tracer = tracer
    }

    func startSpan(named: @autoclosure () -> String) -> any AtatusInternal.BenchmarkSpan {
        SpanWrapper(
            span: tracer
                .spanBuilder(spanName: named())
                .setActive(true)
                .startSpan()
        )
    }
}

private final class SpanWrapper: AtatusInternal.BenchmarkSpan {
    let span: OpenTelemetryApi.Span

    init(span: OpenTelemetryApi.Span) {
        self.span = span
    }

    func stop() {
        span.end()
    }
}
