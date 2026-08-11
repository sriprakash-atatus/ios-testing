/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

extension RUMUser {
    init?(context: AtatusContext) {
        guard let userInfo = context.userInfo else {
            return nil
        }

        if userInfo.id == nil
            && userInfo.anonymousId == nil
            && userInfo.name == nil
            && userInfo.email == nil
            && userInfo.extraInfo.isEmpty {
            return nil
        }

        self.init(userInfo: userInfo)
    }

    init(userInfo: UserInfo) {
        self.init(
            anonymousId: userInfo.anonymousId,
            email: userInfo.email,
            id: userInfo.id,
            name: userInfo.name,
            usrInfo: userInfo.extraInfo
        )
    }
}
