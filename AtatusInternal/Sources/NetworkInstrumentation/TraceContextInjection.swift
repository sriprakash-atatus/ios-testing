/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Defines whether the trace context should be injected into all requests or only sampled ones.
public enum TraceContextInjection: CaseIterable, Sendable {
    /// Injects trace context into all requests irrespective of the sampling decision.
    case all

    /// Injects trace context only into sampled requests.
    case sampled
}
