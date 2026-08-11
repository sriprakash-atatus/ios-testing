/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
@testable import AtatusCore

/*
 Set of Atatus domain extensions over standard types for writing more readable tests.
 Domain agnostic extensions should be put in `SwiftExtensions.swift`.
*/

extension Date {
    /// Returns name of the logs file created at this date.
    var toFileName: String {
        return fileNameFrom(fileCreationDate: self)
    }
}

extension File {
    func makeReadonly() throws {
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: url.path)
    }

    func makeReadWrite() throws {
        try FileManager.default.setAttributes([.immutable: false], ofItemAtPath: url.path)
    }

    /// Reads the file content and returns events data. It assumes that `self` is a batch file storing events in TLV format.
    func readBatchEvents() throws -> [Data] {
        let blocks = try BatchDataBlockReader(input: stream()).all()
        return blocks.map { $0.data }
    }

    func read() throws -> Data {
        try Data(contentsOf: url)
    }
}
