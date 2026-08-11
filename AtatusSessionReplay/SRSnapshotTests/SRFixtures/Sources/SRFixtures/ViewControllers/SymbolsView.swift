/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI

@available(iOS 15.0, *)
struct SymbolsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Monochrome symbol")
            } icon: {
                Image(systemName: "timer")
                    .foregroundStyle(.pink)
            }
            Label {
                Text("Hierarchical symbol")
            } icon: {
                Image(systemName: "timer")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.purple)
            }
            Label {
                Text("Palette symbol")
            } icon: {
                Image(systemName: "timer")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.indigo, .purple)
            }
            Label {
                Text("Multicolor symbol")
            } icon: {
                Image(systemName: "timer")
                    .renderingMode(.original)
            }
        }
    }
}

@available(iOS 15.0, *)
#Preview {
    SymbolsView()
}
