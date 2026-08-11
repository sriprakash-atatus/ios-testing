/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddWebViewTracking` -> `AtatusWebViewTracking`; renamed `dd*` types to `Atatus*`; rebranded the
// licence header.

import UIKit
import WebKit
import AtatusCore
import AtatusWebViewTracking
import class AtatusInternal.CoreRegistry

class WebViewTrackingFixtureViewController: UIViewController, WKNavigationDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // An action sent from native iOS SDK.
        rumMonitor.addAction(type: .custom, name: "Native action")

        // Opens a webview configured to pass all its Browser SDK events to native iOS SDK.
        show(ShopistWebviewViewController(), sender: nil)
    }
}

class ShopistWebviewViewController: UIViewController {
    private let request = URLRequest(url: URL(string: "https://shopist.io")!)
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: UIScreen.main.bounds, configuration: WKWebViewConfiguration())
        view.addSubview(webView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WebViewTracking.enable(
            webView: webView,
            hosts: ["shopist.io"]
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        WebViewTracking.disable(webView: webView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView.load(request)
    }
}
