/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

/// Provides the sample rate of distributed tracing, if configured.
public protocol DistributedTracingSampleRateProvider {
    /// The distributed tracing (first party host tracing) sample rate, if configured. `nil` if first party hosting
    /// was not configured in RUM.
    var distributedTracingSampleRate: SampleRate? { get }
}

extension NetworkInstrumentationFeature: DistributedTracingSampleRateProvider {
    var distributedTracingSampleRate: SampleRate? {
        guard let urlSessionHandler = handlers
            .lazy
            .compactMap({ $0 as? AtatusURLSessionHandlerSupportingDistributedTracing })
            .first
        else {
            return nil
        }
        return urlSessionHandler.distributedTracingSampleRate
    }
}
