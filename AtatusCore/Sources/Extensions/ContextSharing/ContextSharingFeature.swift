/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import AtatusInternal

internal final class ContextSharingFeature: AtatusFeature {
    static var name: String = "_extension_context_sharing"

    var messageReceiver: FeatureMessageReceiver

    init(messageReceiver: FeatureMessageReceiver) {
        self.messageReceiver = messageReceiver
    }
}
