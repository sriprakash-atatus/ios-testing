/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let info = try! TestInfo() // crash if test info are missing or malformed

        let scenario: Scenario = SyntheticScenario() ?? DefaultScenario()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = scenario.start(info: info)
        window?.makeKeyAndVisible()
        return true
    }
}
