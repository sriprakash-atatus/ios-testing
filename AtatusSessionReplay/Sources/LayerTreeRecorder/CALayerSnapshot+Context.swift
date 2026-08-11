/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if os(iOS)
import Foundation
import UIKit
import WebKit

@preconcurrency import AtatusInternal

@available(iOS 13.0, tvOS 13.0, *)
extension CALayerSnapshot {
    /// State shared by all layers captured in one snapshot.
    final class Context {
        let textAndInputPrivacyLevel: TextAndInputPrivacyLevel
        let imagePrivacyLevel: ImagePrivacyLevel

        /// Weak references to web views found while capturing the layer tree.
        let webViewCache: NSHashTable<WKWebView>

        /// Weak references to embedded content views found while capturing the layer tree.
        let embeddedContentViewCache: NSHashTable<UIView>

        init(
            textAndInputPrivacyLevel: TextAndInputPrivacyLevel,
            imagePrivacyLevel: ImagePrivacyLevel,
            webViewCache: NSHashTable<WKWebView> = .weakObjects(),
            embeddedContentViewCache: NSHashTable<UIView> = .weakObjects()
        ) {
            self.textAndInputPrivacyLevel = textAndInputPrivacyLevel
            self.imagePrivacyLevel = imagePrivacyLevel
            self.webViewCache = webViewCache
            self.embeddedContentViewCache = embeddedContentViewCache
        }
    }
}
#endif
