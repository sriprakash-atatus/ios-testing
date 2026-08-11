/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddCrashReporting` -> `AtatusCrashReporting`, `ddLogs` -> `AtatusLogs`, `ddTrace` ->
// `AtatusTrace`; renamed `dd*` types to `Atatus*`; renamed `clientToken` to `licenseKey`; rebranded
// the `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import AtatusCore
import AtatusLogs
import AtatusTrace
import AtatusCrashReporting

@MainActor
enum AtatusSetup {
    static var logger: LoggerProtocol?
    static func initialize() {
        Atatus.initialize(
            with: Atatus.Configuration(licenseKey: "abc", env: "tests"),
            trackingConsent: .granted
        )

        Logs.enable()

        CrashReporting.enable()

        logger = Logger.create(
            with: Logger.Configuration(
                remoteSampleRate: 0,
                consoleLogFormat: .short
            )
        )

        // Trace APIs must be visible:
        Trace.enable()

        logger?.info("It works")
        let span = Tracer.shared().startSpan(operationName: "this too")
        span.finish()
    }
}
