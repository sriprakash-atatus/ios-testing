/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI
import UIKit

// MARK: - Main View

/// SwiftUI wrapper for our storyboard-based UIKit LocationsView
struct LocationsView: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "LocationsView", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        return navigationController
    }

    func updateUIViewController(_: UIViewController, context _: Context) {
        // No updates needed
    }
}

#Preview {
    LocationsView()
}
