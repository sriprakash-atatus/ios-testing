/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the licence header.

import Foundation
import class AtatusInternal.HTTPHeadersWriter

@objc(ATHTTPHeadersWriter)
@objcMembers
@_spi(objc)
public final class objc_HTTPHeadersWriter: NSObject {
    let swiftHTTPHeadersWriter: HTTPHeadersWriter

    public var traceHeaderFields: [String: String] {
        swiftHTTPHeadersWriter.traceHeaderFields
    }

    public init(traceContextInjection: objc_TraceContextInjection) {
        swiftHTTPHeadersWriter = HTTPHeadersWriter(traceContextInjection: traceContextInjection.swiftType)
    }
}
