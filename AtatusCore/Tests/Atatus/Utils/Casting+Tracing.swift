/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddTrace` -> `AtatusTrace`; renamed `dd*`
// types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded the `dd` name to `Atatus` in
// comments and docs; rebranded the licence header.

@testable import AtatusTrace

/*
 NOTE: The casting methods defined here do shadow the ones defined in `Atatus.Casting`.
 The difference is that here in tests we do force unwrapping (`as!`), whereas in `Atatus` we do `as?` with a warning.

 This is needed for expressiveness in testing, where i.e. `XCTAssertNil(span.context.dd?.parentID)` may give a false positive
 without considering if the `parentID` is `nil`. Using `span.context.dd.parentID` mitigates it.
 */

internal extension OTTracer {
    var dd: AtatusTracer { self as! AtatusTracer }
}

internal extension OTSpan {
    var dd: ATSpan { self as! ATSpan }
}

internal extension OTSpanContext {
    var dd: ATSpanContext { self as! ATSpanContext }
}
