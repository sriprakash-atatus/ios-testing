/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the licence header.

import Foundation
import class AtatusInternal.W3CHTTPHeadersWriter

@objc(ATW3CHTTPHeadersWriter)
@objcMembers
@_spi(objc)
public final class objc_W3CHTTPHeadersWriter: NSObject {
    let swiftW3CHTTPHeadersWriter: W3CHTTPHeadersWriter

    public var traceHeaderFields: [String: String] {
        swiftW3CHTTPHeadersWriter.traceHeaderFields
    }

    public init(
        traceContextInjection: objc_TraceContextInjection
    ) {
        swiftW3CHTTPHeadersWriter = W3CHTTPHeadersWriter(
            tracestate: [:],
            traceContextInjection: traceContextInjection.swiftType
        )
    }
}
