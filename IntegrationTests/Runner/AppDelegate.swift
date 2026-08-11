/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import UIKit

var serviceName = "integration-scenarios-service-name"
var appConfiguration: AppConfiguration!

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if Environment.isRunningUnitTests() {
            return false
        }

        appConfiguration = UITestsAppConfiguration()

        // Initialize Atatus SDK
        appConfiguration.initializeSDK()

        return true
    }
}

/// Bridges Swift objects to Objective-C.
@objcMembers
class SwiftGlobals: NSObject {
    class func currentTestScenario() -> Any? { appConfiguration.testScenario }
}
