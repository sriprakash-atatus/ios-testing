/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `_dd` attribute prefix to `_atatus`; renamed the `x-dd-*`
// trace headers to `x-atatus-*`; repointed the intake host at the Atatus site; rebranded the `dd` name
// to `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// Trace propagation headers as explained in
/// https://www.atatus.com/docs/
public enum TracingHTTPHeaders {
    /// Trace propagation header.
    /// It is used both in Tracing and RUM features.
    public static let traceIDField = "x-atatus-trace-id"

    /// Trace propagation header.
    /// In RUM - it allows Atatus to generate the first span from the trace.
    /// In Tracing - it injects the `spanID` of mobile span so downstream spans can be properly linked in distributed tracing.
    public static let parentSpanIDField = "x-atatus-parent-id"

    /// To make sure that the Agent keeps the trace.
    /// It is used both in Tracing and RUM features.
    public static let samplingPriorityField = "x-atatus-sampling-priority"

    /// The Atatus origin of the Trace.
    ///
    /// Setting the value to 'rum' will indicate that the span is reported as a RUM Resource.
    public static let originField = "x-atatus-origin"

    /// The Atatus tags of the Trace.
    public static let tagsField = "x-atatus-tags"

    /// Keys for Atatus tags.
    public enum TagKeys {
        /// The Atatus tag key for the higher order 64 bits of the trace ID.
        public static let traceIDHi = "_atatus.p.tid"
    }
}
