/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI
import UIKit

struct EpisodeDetailHostingController: UIViewControllerRepresentable {
    let episode: Episode

    func makeUIViewController(context _: Context) -> UINavigationController {
        let storyboard = UIStoryboard(name: "EpisodeDetailView", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "EpisodeDetail") as? EpisodeDetailViewController {
            detailVC.episode = episode
            let navigationController = UINavigationController(rootViewController: detailVC)
            navigationController.navigationBar.isHidden = true
            return navigationController
        }
        return UINavigationController()
    }

    func updateUIViewController(_: UINavigationController, context _: Context) {}
}
