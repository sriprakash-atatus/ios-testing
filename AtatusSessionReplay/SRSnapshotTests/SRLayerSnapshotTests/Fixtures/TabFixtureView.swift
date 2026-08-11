/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI

@available(iOS 15.0, *)
struct TabFixtureView: View {
    var body: some View {
        TabView {
            Text("Received")
                .tabItem {
                    Label("Received", systemImage: "tray.and.arrow.down.fill")
                }
                .badge(2)

            Text("Sent")
                .tabItem {
                    Label("Sent", systemImage: "tray.and.arrow.up.fill")
                }

            Text("Account")
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle.fill")
                }
                .badge("!")
        }
    }
}
