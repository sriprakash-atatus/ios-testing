/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import AtatusInternal

internal final class ContextSharingTransformer: FeatureMessageReceiver, ContextValuePublisher {
    @ReadWriteLock
    private var sharedContext: SharedContext? = nil
    @ReadWriteLock
    private var receiver: ContextValueReceiver<SharedContext?>? = nil

    // MARK: - FeatureMessageReceiver

    func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        switch message {
        case .context(let context):
            let newContext = SharedContext(atatusContext: context)
            sharedContext = newContext
            receiver?(newContext)
            return true
        default:
            return false
        }
    }

    // MARK: - ContextValuePublisher

    var initialValue: SharedContext? = nil

    func publish(to receiver: @escaping ContextValueReceiver<SharedContext?>) {
        self.receiver = receiver
        receiver(sharedContext)
    }

    func cancel() {
        receiver = nil
    }
}
