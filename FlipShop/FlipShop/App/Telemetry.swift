/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

#if canImport(AtatusCore) && canImport(AtatusRUM)
import AtatusCore
import AtatusRUM
#endif
#if canImport(AtatusSessionReplay)
import AtatusSessionReplay
#endif
#if canImport(AtatusLogs)
import AtatusLogs
#endif
#if canImport(AtatusTrace)
import AtatusTrace
#endif
#if canImport(AtatusCrashReporting)
import AtatusCrashReporting
#endif

/// The one place the app talks to the Atatus SDK.
///
/// Monitoring starts only when a license key is configured — in `AtatusConfig.plist` in the app bundle,
/// or in the `ATATUS_LICENSE_KEY` environment variable of the Xcode scheme — so the shop runs the same
/// with or without it. Without the Atatus packages linked, this compiles to nothing.
enum Telemetry {
    private static let configFileName = "AtatusConfig"

    static func start() {
        #if canImport(AtatusCore) && canImport(AtatusRUM)
        guard let licenseKey = value(for: "AtatusLicenseKey", environment: "ATATUS_LICENSE_KEY") else {
            return
        }

        Atatus.initialize(
            with: Atatus.Configuration(
                licenseKey: licenseKey,
                env: value(for: "AtatusEnvironment", environment: "ATATUS_ENV") ?? "demo",
                serverUrl: value(for: "AtatusServerURL", environment: "ATATUS_SERVER_URL"),
                service: "flipshop-ios"
            ),
            trackingConsent: .granted
        )

        var rum = RUM.Configuration(applicationID: value(for: "AtatusRUMApplicationID", environment: "ATATUS_RUM_APPLICATION_ID") ?? "")
        rum.swiftUIViewsPredicate = DefaultSwiftUIRUMViewsPredicate()
        rum.swiftUIActionsPredicate = DefaultSwiftUIRUMActionsPredicate(isLegacyDetectionEnabled: true)
        rum.trackFrustrations = true
        rum.trackBackgroundEvents = true
        RUM.enable(with: rum)

        #if canImport(AtatusLogs)
        Logs.enable(with: Logs.Configuration())
        #endif

        #if canImport(AtatusTrace)
        Trace.enable(with: Trace.Configuration(sampleRate: 100))
        #endif

        #if canImport(AtatusCrashReporting)
        CrashReporting.enable()
        #endif

        #if canImport(AtatusSessionReplay)
        // Card and password fields stay masked; product photos and taps are recorded.
        SessionReplay.enable(
            with: SessionReplay.Configuration(
                replaySampleRate: 100,
                textAndInputPrivacyLevel: .maskSensitiveInputs,
                imagePrivacyLevel: .maskNone,
                touchPrivacyLevel: .show
            )
        )
        #endif
        #endif
    }

    private static func value(for plistKey: String, environment variable: String) -> String? {
        if let value = ProcessInfo.processInfo.environment[variable]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            return value
        }
        guard
            let url = Bundle.main.url(forResource: configFileName, withExtension: "plist"),
            let values = NSDictionary(contentsOf: url) as? [String: Any],
            let value = (values[plistKey] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty
        else {
            return nil
        }
        return value
    }
}

extension View {
    /// Names this screen in RUM. A no-op when the SDK isn't linked.
    func trackScreen(_ name: String) -> some View {
        #if canImport(AtatusRUM)
        return trackRUMView(name: name)
        #else
        return self
        #endif
    }
}
