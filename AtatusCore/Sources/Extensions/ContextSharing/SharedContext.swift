/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

/// Objective-C compatible type that exposes selected properties from `AtatusContext` to Objective-C.
///
/// This class is intended for internal use, primarily by cross-platform libraries that need to access
/// Atatus context information from Objective-C code. Can be extended with other properties as long as
/// they are Objective-C compatible.
@objc(ATSharedContext)
@objcMembers
@_spi(Internal)
public class SharedContext: NSObject {
    public let userId: String?
    public let accountId: String?

    init(atatusContext: AtatusContext) {
        userId = atatusContext.userInfo?.id
        accountId = atatusContext.accountInfo?.id
    }
}
