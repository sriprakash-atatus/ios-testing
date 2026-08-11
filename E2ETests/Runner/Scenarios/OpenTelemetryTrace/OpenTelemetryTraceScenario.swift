/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddTrace` ->
// `AtatusTrace`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence
// header.

import Foundation
import UIKit
import AtatusTrace
import AtatusCore
import OpenTelemetryApi

struct TraceScenario: Scenario {
    func start(info: TestInfo) -> UIViewController {
        Atatus.verbosityLevel = .debug

        Atatus.initialize(
            with: .e2e(info: info),
            trackingConsent: .granted
        )

        Trace.enable(
            with: .init(
                urlSessionTracking: .init(
                    firstPartyHostsTracing: .trace(
                        hosts: ["httpbin.org"],
                        sampleRate: 100,
                        traceControlInjection: .all
                    )
                )
            )
        )

        OpenTelemetry.registerTracerProvider(
            tracerProvider: OTelTracerProvider()
        )

        let tracer = OpenTelemetry
            .instance
            .tracerProvider
            .get(instrumentationName: "", instrumentationVersion: nil)

        URLSessionInstrumentation.enableDurationBreakdown(
            with: .init(
                delegateClass: DistributedTraceDelegate.self
            )
        )

        let delegate = DistributedTraceDelegate()
        let urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

        return OpenTelemetryTraceViewController(tracer: tracer, urlSession: urlSession)
    }
}
