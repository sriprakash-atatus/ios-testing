/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Synchronizes the work of `FileReader` on given read/write queue.
internal final class DataReader: Reader {
    /// Queue used to synchronize reads and writes for the feature.
    internal let queue: DispatchQueue
    private let fileReader: Reader

    init(readWriteQueue: DispatchQueue, fileReader: Reader) {
        self.queue = readWriteQueue
        self.fileReader = fileReader
    }

    func readFiles(limit: Int) -> [ReadableFile] {
        queue.sync {
            self.fileReader.readFiles(limit: limit)
        }
    }

    func readBatch(from file: ReadableFile) -> Batch? {
        queue.sync {
            self.fileReader.readBatch(from: file)
        }
    }

    func markBatchAsRead(_ batch: Batch, reason: BatchDeletedMetric.RemovalReason) {
        queue.sync {
            self.fileReader.markBatchAsRead(batch, reason: reason)
        }
    }
}
