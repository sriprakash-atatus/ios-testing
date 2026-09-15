/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

@main
struct FlipShopApp: App {
    @State private var container: AppContainer

    init() {
        // Started first, so the agent sees the app from its first screen.
        Telemetry.start()
        _container = State(initialValue: AppContainer())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .injectDependencies(container)
        }
    }
}
