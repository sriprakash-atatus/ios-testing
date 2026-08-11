/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddWebViewTracking` -> `AtatusWebViewTracking`;
// renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
#if canImport(WebKit)
import WebKit

@testable import AtatusWebViewTracking

public final class ATUserContentController: WKUserContentController {
    public typealias NameHandlerPair = (name: String, handler: WKScriptMessageHandler)
    public private(set) var messageHandlers = [NameHandlerPair]()

    override public func add(_ scriptMessageHandler: WKScriptMessageHandler, name: String) {
        messageHandlers.append((name: name, handler: scriptMessageHandler))
    }

    override public func removeScriptMessageHandler(forName name: String) {
        messageHandlers = messageHandlers.filter {
            return $0.name != name
        }
    }
}

public final class MockMessageHandler: NSObject, WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) { }
}

public final class MockScriptMessage: WKScriptMessage {
    private let _body: Any
    private weak var _webView: WKWebView?

    public init(body: Any, webView: WKWebView? = nil) {
        _body = body
        _webView = webView
    }

    override public var body: Any { _body }
    override public weak var webView: WKWebView? { _webView }
}

#endif
