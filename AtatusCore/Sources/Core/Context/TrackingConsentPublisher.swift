/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// Publishes the user consent to receiver.
internal final class TrackingConsentPublisher: ContextValuePublisher {
    let initialValue: TrackingConsent

    private var receiver: ContextValueReceiver<TrackingConsent>?

    var consent: TrackingConsent {
        didSet { receiver?(consent) }
    }

    init(consent: TrackingConsent) {
        self.initialValue = consent
        self.consent = consent
    }

    func publish(to receiver: @escaping ContextValueReceiver<TrackingConsent>) {
        self.receiver = receiver
    }

    func cancel() {
        receiver = nil
    }
}
