/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Launch initial screen depending on the launch configuration
        guard let storyboard = appConfiguration.initialStoryboard() else {
            assertionFailure("No initial storyboard defined in app configuration")
            return
        }

        launch(storyboard: storyboard, in: scene)
    }

    func launch(storyboard: UIStoryboard, in scene: UIScene) {
        let window = UIWindow(windowScene: scene as! UIWindowScene)
        window.rootViewController = storyboard.instantiateInitialViewController()!
        window.makeKeyAndVisible()
        self.window = window
    }
}
