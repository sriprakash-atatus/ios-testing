/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `com.ddhq.*` identifiers to `com.atatus.*`; rebranded the licence header.

import Foundation
import AtatusInternal

/// A `DataStore` that schedules all operations on its internal queue.
public final class DataStoreAsyncMock: DataStore {
    @ReadWriteLock
    public var storage: [String: DataStoreValueResult]

    private let queue = DispatchQueue(label: "com.atatus.datastore-async-mock")

    public init(storage: [String: DataStoreValueResult] = [:]) {
        self.storage = storage
    }

    public func setValue(_ value: Data, forKey key: String, version: DataStoreKeyVersion) {
        queue.async {
            self.storage[key] = .value(value, version)
        }
    }

    public func value(forKey key: String, callback: @escaping (DataStoreValueResult) -> Void) {
        queue.async {
            callback(self.storage[key] ?? .noValue)
        }
    }

    public func removeValue(forKey key: String) {
        queue.async {
            self.storage[key] = nil
        }
    }

    public func clearAllData() {
        queue.async {
            self.storage.removeAll()
        }
    }

    /// Function to wait until all scheduled operations complete.
    public func flush() {
        queue.sync {}
    }
}
