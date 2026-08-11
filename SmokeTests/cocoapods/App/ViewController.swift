/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddCrashReporting` -> `AtatusCrashReporting`, `ddFlags` -> `AtatusFlags`, `ddLogs` ->
// `AtatusLogs`, `ddProfiling` -> `AtatusProfiling`, `ddRUM` -> `AtatusRUM`,
// `ddSessionReplay` -> `AtatusSessionReplay`, `ddTrace` -> `AtatusTrace`; renamed `clientToken`
// to `licenseKey`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence
// header.

import UIKit
import AtatusCore
import AtatusLogs
import AtatusTrace
import AtatusRUM
import AtatusCrashReporting
import AtatusSessionReplay  // it should compile for iOS and tvOS, but APIs are only available on iOS
import AtatusFlags
import AtatusProfiling
import OpenTelemetryApi

internal class ViewController: UIViewController {
    private var logger: LoggerProtocol! // swiftlint:disable:this implicitly_unwrapped_optional

    override func viewDidLoad() {
        super.viewDidLoad()

        Atatus.initialize(
            with: Atatus.Configuration(licenseKey: "abc", env: "tests"),
            trackingConsent: .granted
        )

        Logs.enable()

        CrashReporting.enable()

        self.logger = Logger.create(
            with: Logger.Configuration(
                remoteSampleRate: 0,
                consoleLogFormat: .short
            )
        )

        // RUM APIs must be visible:
        RUM.enable(with: .init(applicationID: "app-id"))
        RUMMonitor.shared().startView(viewController: self)

        // Trace APIs must be visible:
        Trace.enable()

        // Register tracer provider
        OpenTelemetry.registerTracerProvider(
            tracerProvider: OTelTracerProvider()
        )

        logger.info("It works")

        let otSpan = Tracer.shared().startSpan(operationName: "OT Span")
        otSpan.finish()

        // otel tracer
        let tracer = OpenTelemetry
           .instance
           .tracerProvider
           .get(instrumentationName: "", instrumentationVersion: nil)
        let otelSpan = tracer.spanBuilder(spanName: "OTel span").startSpan()
        otelSpan.end()

        #if os(iOS)
        SessionReplay.enable(with: .init(replaySampleRate: 0))
        #endif

        addLabel()
    }

    private func addLabel() {
        let label = UILabel()
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(label)

        label.text = "Testing..."
        label.textColor = .white
        label.sizeToFit()
        label.center = view.center
    }
}
