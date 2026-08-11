/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal
import OpenTelemetryApi

/// The Atatus implementation of OpenTelemetry `TracerProvider`.
/// It takes the Atatus SDK instance as a dependency and returns the tracer from it.
///
/// Usage:
///
/// ```swift
/// import OpenTelemetryApi
/// import AtatusTrace
///
/// // Register the tracer provider
/// OpenTelemetry.registerTracerProvider(
///     tracerProvider: OTelTracerProvider()
/// )
///
/// // Get the tracer
/// let tracer = OpenTelemetry
///     .instance
///     .tracerProvider
///     .get(instrumentationName: "", instrumentationVersion: nil)
///
/// // Start a span
/// let span = tracer
///     .spanBuilder(spanName: "OperationName")
///     .startSpan()
/// ```
public class OTelTracerProvider: OpenTelemetryApi.TracerProvider {
    private weak var core: AtatusCoreProtocol?

    /// Creates a tracer provider with the given Atatus SDK instance.
    /// - Parameter core: the instance of Atatus SDK the Trace feature was enabled in (global instance by default)
    public init(in core: AtatusCoreProtocol = CoreRegistry.default) {
        self.core = core
    }

    /// Returns a tracer with the given instrumentation name and version.
    /// - Parameters:
    ///   - instrumentationName: the name of the instrumentation library, not the name of the instrumented library
    ///     Note: This is ignored, as the Atatus SDK works on concept of core.
    ///   - instrumentationVersion:  The version of the instrumentation library (e.g., "semver:1.0.0"). Optional
    ///     Note: This is ignored, as the Atatus SDK works on concept of core.
    ///   - schemaUrl: The schema url. Optional
    ///     Note: This is ignored in Atatus SDK.
    ///   - attributes: Attributes to be associated with spans created by this tracer. Optional.
    ///     Note: This is ignored by the Atatus SDK. To configure default tags for the tracer, use `Trace.Configuration`
    ///     passed to `Trace.enable()`.
    public func get(
        instrumentationName: String,
        instrumentationVersion: String?,
        schemaUrl: String?,
        attributes: [String: OpenTelemetryApi.AttributeValue]?
    ) -> any OpenTelemetryApi.Tracer {
        return get(instrumentationName: instrumentationName, instrumentationVersion: instrumentationVersion)
    }

    /// Returns a tracer with the given instrumentation name and version.
    /// - Parameters:
    ///   - instrumentationName: the name of the instrumentation library, not the name of the instrumented library
    ///     Note: This is ignored, as the Atatus SDK works on concept of core.
    ///   - instrumentationVersion:  The version of the instrumentation library (e.g., "semver:1.0.0"). Optional
    ///     Note: This is ignored, as the Atatus SDK works on concept of core.
    public func get(instrumentationName: String, instrumentationVersion: String?) -> OpenTelemetryApi.Tracer {
        do {
            guard !(core is NOPAtatusCore) else {
                throw ProgrammerError(
                    description: "Atatus SDK must be initialized and Trace feature must be enabled before calling `OTelTracerProvider.get(instrumentationName:instrumentationVersion:)`."
                )
            }
            guard let feature = core?.get(feature: TraceFeature.self) else {
                throw ProgrammerError(
                    description: "Trace feature must be enabled before calling `OTelTracerProvider.get(instrumentationName:instrumentationVersion:)`."
                )
            }

            // Send tracer API usage to telemetry
            core?.telemetry.configuration(tracerAPI: "OpenTelemetry", tracerAPIVersion: OpenTelemetry.version)

            return feature.tracer
        } catch {
            consolePrint("\(error)", .error)
            return ATNoopTracer()
        }
    }
}
