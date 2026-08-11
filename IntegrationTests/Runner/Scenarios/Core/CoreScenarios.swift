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

internal class StopCoreScenario: TestScenario {
    static let storyboardName = "StopCoreScenario"

    required init() { }

    func configureFeatures() {
        // Enable RUM
        var rumConfig = RUM.Configuration(applicationID: "rum-application-id")
        rumConfig.customEndpoint = Environment.serverMockConfiguration()?.rumEndpoint
        rumConfig.uiKitViewsPredicate = StopCoreScenarioUIKitRUMViewsPredicate()
        rumConfig.uiKitActionsPredicate = DefaultUIKitRUMActionsPredicate()
        rumConfig.urlSessionTracking = .init()
        RUM.enable(with: rumConfig)

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

        URLSessionInstrumentation.enableDurationBreakdown(with: .init(delegateClass: CustomURLSessionDelegate.self))
    }
}

private struct StopCoreScenarioUIKitRUMViewsPredicate: UIKitRUMViewsPredicate {
    func rumView(for viewController: UIViewController) -> RUMView? {
        switch viewController {
        case is CSHomeViewController:
            return RUMView(name: "Home")
        case is CSPictureViewController:
            return RUMView(name: "Picture")
        default:
            return nil
        }
    }
}
