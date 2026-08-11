/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

// ATCHG: Replaced the multi-region dd site list (us1/us3/us5/eu1/ap1/ap2/uk1/us1_fed/us2_fed)
// with the single Atatus intake site, mirroring `AtatusSite` in the Atatus Android agent.
/// Defines the Atatus site you can send tracked data to.
public enum AtatusSite: String {
    /// The Atatus site: [mo-rx.atatus.com](https://mo-rx.atatus.com).
    case atatus

    // ATCHG: Added `serverUrl` override so the intake host can be pointed at a testing
    // endpoint (e.g. ngrok) without hardcoding, matching `AtatusSite.serverUrl` on Android.
    /// Global override for the intake endpoint.
    ///
    /// Defaults to the `ATATUS_SERVER_URL` environment variable when present. When set, it takes
    /// precedence over the site's default intake host.
    @ReadWriteLock
    public static var serverUrl: String? = ProcessInfo.processInfo.environment["ATATUS_SERVER_URL"]
    // ATCHG: End
}
// ATCHG: End

extension AtatusSite {
    // ATCHG: Default production intake host for the Atatus site.
    /// The host name of the intake for this site.
    private var intakeHostName: String {
        switch self {
        case .atatus: return "mo-rx.atatus.com"
        }
    }
    // ATCHG: End

    /// The intake endpoint URL.
    public var endpoint: URL {
        // ATCHG: Resolve `serverUrl` first so config-driven endpoints win over the default host.
        if let serverUrl = AtatusSite.serverUrl, let overrideURL = URL(string: serverUrl) {
            return overrideURL
        }
        // ATCHG: End
        // swiftlint:disable:next force_unwrapping
        return URL(string: "https://\(intakeHostName)")!
    }
}
