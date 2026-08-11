/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

/// `FeatureMessageReceiver` that records received telemetry events.
public class TelemetryReceiverMock: FeatureMessageReceiver {
    @ReadWriteLock
    public private(set) var messages: [TelemetryMessage] = []

    public init() {}

    public func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        guard case let .telemetry(message) = message else {
            return false
        }

        messages.append(message)
        return true
    }
}
