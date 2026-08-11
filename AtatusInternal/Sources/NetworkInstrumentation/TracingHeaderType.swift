/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `x-dd-*` trace headers to `x-atatus-*`; repointed the
// intake host at the Atatus site; rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import Foundation

/// The type of the tracing header injected to requests.
///
/// - `atatus` - [Atatus's `x-atatus-*` header](https://www.atatus.com/docs/).
/// - `b3` - Open Telemetry B3 [Single header](https://github.com/openzipkin/b3-propagation#single-headers).
/// - `b3multi` - Open Telemetry B3 [Multiple headers](https://github.com/openzipkin/b3-propagation#multiple-headers).
/// - `tracecontext` - W3C [Trace Context header](https://www.w3.org/TR/trace-context/#tracestate-header)
@frozen
public enum TracingHeaderType: Hashable, Sendable {
    case atatus
    case b3
    case b3multi
    case tracecontext
}
