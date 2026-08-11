/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

/// The set of messages that can be transmitted on the Features message bus.
public enum FeatureMessage {
    /// A custom payload message.
    case payload(Any)

    /// A web-view message.
    ///
    /// Represent a Browser SDK event sent through the JS bridge.
    case webview(WebViewMessage)

    /// Session Replay records produced by an embedded renderer.
    case embeddedContent(EmbeddedContentMessage)

    /// A core context message.
    ///
    /// The core will send updated context through the bus. Do not send new context values
    /// from a Feature or Integration.
    case context(AtatusContext)

    /// A telemetry message.
    ///
    /// The core can send telemetry data coming from all Features.
    case telemetry(TelemetryMessage)
}
