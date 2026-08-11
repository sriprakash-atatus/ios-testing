/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddFlags` -> `AtatusFlags`, `ddProfiling`
// -> `AtatusProfiling`, `ddRUM` -> `AtatusRUM`, `ddSessionReplay` -> `AtatusSessionReplay`,
// `ddTrace` -> `AtatusTrace`; renamed `dd*` types to `Atatus*`; rebranded the licence header.

import UIKit
import AtatusRUM
import AtatusSessionReplay // it should compile for iOS and tvOS, but APIs are only available on iOS
import AtatusTrace
import AtatusFlags
import AtatusProfiling
@preconcurrency import OpenTelemetryApi

internal class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        AtatusSetup.initialize()

        // RUM APIs must be visible:
        RUM.enable(
            with: .init(
                applicationID: "app-id",
                onSessionStart: { sessionID, _ in
                    print("Session ID is \(sessionID)")
                }
            )
        )
        RUMMonitor.shared().startView(viewController: self)

        // Trace APIs must be visible:
        Trace.enable()
        OpenTelemetry.registerTracerProvider(
            tracerProvider: OTelTracerProvider()
        )

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
        // Session Replay API must be visible:
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
