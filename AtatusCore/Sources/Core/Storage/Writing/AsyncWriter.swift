/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// Writer performing writes asynchronously on a given queue.
internal struct AsyncWriter: Writer {
    private let writer: Writer
    private let queue: DispatchQueue

    init(execute otherWriter: Writer, on queue: DispatchQueue) {
        self.writer = otherWriter
        self.queue = queue
    }

    func write<T: Encodable, M: Encodable>(value: T, metadata: M?, completion: @escaping CompletionHandler) {
        queue.async { writer.write(value: value, metadata: metadata, completion: completion) }
    }
}

internal struct NOPWriter: Writer {
    func write<T: Encodable, M: Encodable>(value: T, metadata: M?, completion: @escaping CompletionHandler) {
        completion()
    }
}
