/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; renamed `com.ddhq.*`
// identifiers to `com.atatus.*`; rebranded the licence header.

#if canImport(WebKit)

import Foundation
import WebKit
import AtatusInternal

internal class ATScriptMessageHandler: NSObject, WKScriptMessageHandler {
    static let name = "AtatusEventBridge"

    let emitter: MessageEmitter

    let queue = DispatchQueue(
        label: "com.atatus.JSEventBridge",
        target: .global(qos: .userInteractive)
    )

    init(emitter: MessageEmitter) {
        self.emitter = emitter
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let hash = message.webView.map { String($0.hash) }
        // message.body must be called within UI thread
        let body = message.body
        queue.async {
            self.emitter.send(body: body, slotId: hash)
        }
    }
}

extension ATScriptMessageHandler: Flushable {
    func flush() {
        queue.sync { }
    }
}

#endif
