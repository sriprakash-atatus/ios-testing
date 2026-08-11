/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the licence header.

#if os(iOS)
import AtatusInternal
import UIKit
import WebKit

@testable import AtatusSessionReplay

@available(iOS 13.0, tvOS 13.0, *)
extension CALayerSnapshot.Context {
    static func mockAny(
        textAndInputPrivacyLevel: TextAndInputPrivacyLevel = .maskAll,
        imagePrivacyLevel: ImagePrivacyLevel = .maskAll,
        webViewCache: NSHashTable<WKWebView> = .weakObjects(),
        embeddedContentViewCache: NSHashTable<UIView> = .weakObjects()
    ) -> Self {
        .init(
            textAndInputPrivacyLevel: textAndInputPrivacyLevel,
            imagePrivacyLevel: imagePrivacyLevel,
            webViewCache: webViewCache,
            embeddedContentViewCache: embeddedContentViewCache
        )
    }
}
#endif
