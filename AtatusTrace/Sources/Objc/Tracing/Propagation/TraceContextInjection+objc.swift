/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

/// Defines whether the trace context should be injected into all requests or only sampled ones.
@objc(ATTraceContextInjection)
@_spi(objc)
public enum objc_TraceContextInjection: Int {
    internal var swiftType: AtatusInternal.TraceContextInjection {
        switch self {
        case .all:
            return .all
        case .sampled:
            return .sampled
        }
    }

    /// Injects trace context into all requests irrespective of the sampling decision.
    case all

    /// Injects trace context only into sampled requests.
    case sampled
}
