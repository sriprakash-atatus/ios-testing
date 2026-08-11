/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation
import OpenTelemetryApi

/// A no-op TracerProvider that crashes if the tracer is actually used.
class NOPTracerProvider: TracerProvider {
    func get(
        instrumentationName: String,
        instrumentationVersion: String?,
        schemaUrl: String?,
        attributes: [String: AttributeValue]?
    ) -> any Tracer {
        return NOPTracer()
    }
}

/// A no-op Tracer that crashes if used.
private class NOPTracer: Tracer {
    func spanBuilder(spanName: String) -> any SpanBuilder { // swiftlint:disable:this unavailable_function
        fatalError("NOPTracer should not be used. Tracing is not implemented in Benchmarks.")
    }
}
