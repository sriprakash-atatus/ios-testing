/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// A type, writing data.
public protocol Writer {
    /// Encodes given encodable value and metadata, and writes to the destination.
    /// - Parameters:
    ///   - value: Encodable value to write.
    ///   - metadata: Encodable metadata to write.
    ///   - completion: The block to execute after the write task is completed.
    func write<T: Encodable, M: Encodable>(value: T, metadata: M?, completion: @escaping CompletionHandler)
}

extension Writer {
    /// Encodes given encodable value and writes to the destination.
    /// Uses `write(value:metadata:)` with `nil` metadata.
    ///
    /// - Parameter value: Encodable value to write.
    public func write<T: Encodable>(value: T) {
        write(value: value, completion: {})
    }

    /// Encodes given encodable value and writes to the destination.
    /// Uses `write(value:metadata:)` with `nil` metadata.
    ///
    /// - Parameters:
    ///   - value: Encodable value to write.
    ///   - completion: The block to execute after the write task is completed.
    public func write<T: Encodable>(value: T, completion: @escaping CompletionHandler) {
        let metadata: Data? = nil
        write(value: value, metadata: metadata, completion: completion)
    }

    /// Encodes given encodable value and metadata, and writes to the destination.
    /// - Parameters:
    ///   - value: Encodable value to write.
    ///   - metadata: Encodable metadata to write.
    public func write<T: Encodable, M: Encodable>(value: T, metadata: M?) {
        write(value: value, metadata: metadata, completion: {})
    }
}
