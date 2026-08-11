/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the licence header.

import Foundation
import class AtatusInternal.B3HTTPHeadersWriter

@objc(ATInjectEncoding)
@_spi(objc)
public enum objc_InjectEncoding: Int {
    case multiple = 0
    case single = 1
}

private extension B3HTTPHeadersWriter.InjectEncoding {
    init(_ value: objc_InjectEncoding) {
        switch value {
        case .single:
            self = .single
        case .multiple:
            self = .multiple
        }
    }
}

@objc(ATB3HTTPHeadersWriter)
@objcMembers
@_spi(objc)
public final class objc_B3HTTPHeadersWriter: NSObject {
    let swiftB3HTTPHeadersWriter: B3HTTPHeadersWriter

    public var traceHeaderFields: [String: String] {
        swiftB3HTTPHeadersWriter.traceHeaderFields
    }

    public init(
        injectEncoding: objc_InjectEncoding = .single,
        traceContextInjection: objc_TraceContextInjection = .sampled
    ) {
        swiftB3HTTPHeadersWriter = B3HTTPHeadersWriter(
            injectEncoding: .init(injectEncoding),
            traceContextInjection: traceContextInjection.swiftType
        )
    }
}
