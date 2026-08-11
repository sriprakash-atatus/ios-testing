/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddLogs` ->
// `AtatusLogs`, `ddRUM` -> `AtatusRUM`, `ddTrace` -> `AtatusTrace`; rebranded the licence header.

import Foundation
import AtatusTrace
import AtatusRUM
import AtatusLogs
import AtatusCore

internal class TrackingConsentBaseScenario {
    func configureFeatures() {
        // Enable RUM
        var rumConfig = RUM.Configuration(applicationID: "rum-application-id")
        rumConfig.customEndpoint = Environment.serverMockConfiguration()?.rumEndpoint
        rumConfig.uiKitViewsPredicate = DefaultUIKitRUMViewsPredicate()
        rumConfig.uiKitActionsPredicate = DefaultUIKitRUMActionsPredicate()
        rumConfig.urlSessionTracking = .init()
        RUM.enable(with: rumConfig)

        // Enable duration breakdown for detailed timing data
        URLSessionInstrumentation.enableDurationBreakdown(with: .init(delegateClass: CustomURLSessionDelegate.self))

        // Enable Trace
        var traceConfig = Trace.Configuration()
        traceConfig.networkInfoEnabled = true
        traceConfig.customEndpoint = Environment.serverMockConfiguration()?.tracesEndpoint
        Trace.enable(with: traceConfig)

        // Enable Logs
        Logs.enable(
            with: Logs.Configuration(
                customEndpoint: Environment.serverMockConfiguration()?.logsEndpoint
            )
        )
    }
}

/// Tracking consent scenario, which launches the app with `.pending` consent value.
final class TrackingConsentStartPendingScenario: TrackingConsentBaseScenario, TestScenario {
    static let storyboardName = "TrackingConsentScenario"
    let initialTrackingConsent: TrackingConsent = .pending

    override func configureFeatures() {
        super.configureFeatures()
    }
}

/// Tracking consent scenario, which launches the app with `.granted` consent value.
final class TrackingConsentStartGrantedScenario: TrackingConsentBaseScenario, TestScenario {
    static let storyboardName = "TrackingConsentScenario"
    let initialTrackingConsent: TrackingConsent = .granted

    override func configureFeatures() {
        super.configureFeatures()
    }
}
