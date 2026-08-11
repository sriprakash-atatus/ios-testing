/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddLogs` ->
// `AtatusLogs`, `ddRUM` -> `AtatusRUM`, `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the
// licence header.

import UIKit
import AtatusCore
import AtatusRUM
import AtatusLogs
import AtatusSessionReplay

private struct WebViewTrackingScenarioPredicate: UIKitRUMViewsPredicate {
    private let defaultPredicate = DefaultUIKitRUMViewsPredicate()

    func rumView(for viewController: UIViewController) -> RUMView? {
        if viewController is ShopistWebviewViewController {
            return nil // do not consider the webview itself as RUM view
        }
        // Exclude Screen Time view controllers (ST-prefixed) injected by iOS on top of WKWebView.
        if String(describing: type(of: viewController)).hasPrefix("ST") {
            return nil
        }
        return defaultPredicate.rumView(for: viewController)
    }
}

final class WebViewTrackingScenario: TestScenario {
    static var storyboardName: String = "WebViewTrackingScenario"

    func configureFeatures() {
        RUM.enable(
            with: RUM.Configuration(
                applicationID: "rum-application-id",
                uiKitViewsPredicate: WebViewTrackingScenarioPredicate(),
                customEndpoint: Environment.serverMockConfiguration()?.rumEndpoint
            )
        )

        SessionReplay.enable(
            with: SessionReplay.Configuration(
                replaySampleRate: 100,
                customEndpoint: Environment.serverMockConfiguration()?.srEndpoint
            )
        )

        Logs.enable(
            with: Logs.Configuration(
                customEndpoint: Environment.serverMockConfiguration()?.logsEndpoint
            )
        )
    }
}
