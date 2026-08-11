/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddWebViewTracking` -> `AtatusWebViewTracking`;
// rebranded the licence header.

import UIKit
import WebKit
import AtatusWebViewTracking

class SessionReplayWebViewController: UIViewController, WKUIDelegate {
    var webView: WKWebView! // swiftlint:disable:this implicitly_unwrapped_optional

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WebViewTracking.enable(
            webView: webView,
            hosts: ["atatus.dev"]
        )
    }

    func load(url string: String) {
        let url = URL(string: string)!
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

class SessionReplayBasicTextViewController: SessionReplayWebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        load(url: "https://atatus.dev/browser-sdk-test-playground/webview-support/#basic-text")
    }
}

class SessionReplayImageViewController: SessionReplayWebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        load(url: "https://atatus.dev/browser-sdk-test-playground/webview-support/#image")
    }
}

class SessionReplayViewPortViewController: SessionReplayWebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        load(url: "https://atatus.dev/browser-sdk-test-playground/webview-support/#viewport-unit")
    }
}

class SessionReplayShadowDOMViewController: SessionReplayWebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        load(url: "https://atatus.dev/browser-sdk-test-playground/webview-support/#shadow-dom")
    }
}

class SessionReplayTimestampViewController: SessionReplayWebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        load(url: "https://atatus.dev/browser-sdk-test-playground/webview-support/#click-event")
    }
}
