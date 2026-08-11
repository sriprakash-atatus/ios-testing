/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

public struct FeatureMessageReceiverMock: FeatureMessageReceiver {
    public typealias ReceiverClosure = (FeatureMessage) -> Void

    @ReadWriteLock
    public private(set) var messages: [FeatureMessage] = []

    public var receiver: ReceiverClosure?

    /// Creates a Feature Message Receiever  mock.
    /// - Parameters:
    ///   - expectation: Test expectation that will be fullfilled when a message is
    ///                  received.
    ///   - receiver: The receiver closure called when receiving a message.
    public init(receiver: ReceiverClosure? = nil) {
        self.receiver = receiver
    }

    public func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        messages.append(message)
        receiver?(message)
        return true
    }
}
