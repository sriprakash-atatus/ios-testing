/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

extension RUMAccount {
    init?(context: AtatusContext) {
        guard let accountInfo = context.accountInfo else {
            return nil
        }

        self.init(accountInfo: accountInfo)
    }

    init(accountInfo: AccountInfo) {
        self.init(
            id: accountInfo.id,
            name: accountInfo.name,
            accountInfo: accountInfo.extraInfo
        )
    }
}
