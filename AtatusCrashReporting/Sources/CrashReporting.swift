/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; repointed the intake host at the
// Atatus site; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

/// Enable iOS Crash Reporting and Error Tracking to get comprehensive crash reports and
/// error trends with Real User Monitoring. With this feature, you can access:
///
/// - Aggregated iOS crash dashboards and attributes
/// - Symbolicated iOS crash reports
/// - Trend analysis with iOS error tracking
///
/// In order to symbolicate your stack traces, find and upload your .dSYM files to Atatus.
/// Then, verify your configuration by running a test crash and restarting your application.
///
/// Your crash reports appear in [Error Tracking](https://www.atatus.com/).
public final class CrashReporting {
    /// Initializes the Atatus Crash Reporter using the default
    /// `KSCrash` plugin.
    public static func enable(in core: AtatusCoreProtocol = CoreRegistry.default) {
        enable(with: try KSCrashPlugin(telemetry: core.telemetry), in: core)
    }

    /// Initializes the Atatus Crash Reporter with a custom Crash Reporting Plugin.
    ///
    /// The custom plugin will be responsible for:
    /// - Provide crash report
    /// - Store context data associated with crashes
    /// - Provide backtraces
    public static func enable(with plugin: @autoclosure () throws -> CrashReportingPlugin, in core: AtatusCoreProtocol = CoreRegistry.default) {
        do {
            // To ensure the correct registration order between Core and Features,
            // the entire initialization flow is synchronized on the main thread.
            try runOnMainThreadSync {
                try enableOrThrow(with: plugin(), in: core)
            }
        } catch let error {
            consolePrint("\(error)", .error)
        }
    }

    internal static func enableOrThrow(with plugin: CrashReportingPlugin, in core: AtatusCoreProtocol) throws {
        guard !(core is NOPAtatusCore) else {
            throw ProgrammerError(
                description: "Atatus SDK must be initialized before calling `CrashReporting.enable()`."
            )
        }

        let contextProvider = CrashContextCoreProvider()

        let reporter = CrashReportingFeature(
            crashReportingPlugin: plugin,
            crashContextProvider: contextProvider,
            sender: MessageBusSender(core: core),
            messageReceiver: contextProvider,
            telemetry: core.telemetry
        )

        try core.register(feature: reporter)

        if let backtraceReporter = plugin.backtraceReporter {
            try core.register(backtraceReporter: backtraceReporter)
        }

        reporter.sendCrashReportIfFound()

        core.telemetry.configuration(trackErrors: true)
    }
}

/// Enable iOS Crash Reporting and Error Tracking to get comprehensive crash reports and
/// error trends with Real User Monitoring. With this feature, you can access:
///
/// - Aggregated iOS crash dashboards and attributes
/// - Symbolicated iOS crash reports
/// - Trend analysis with iOS error tracking
///
/// In order to symbolicate your stack traces, find and upload your .dSYM files to Atatus.
/// Then, verify your configuration by running a test crash and restarting your application.
///
/// Your crash reports appear in [Error Tracking](https://www.atatus.com/).
@available(swift, obsoleted: 1)
@objc(ATCrashReporter)
public final class objc_CrashReporting: NSObject {
    /// Initializes the Atatus Crash Reporter.
    @objc
    public static func enable() {
        CrashReporting.enable()
    }
}
