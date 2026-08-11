/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Files

/// A location of a file.
///
/// It doesn't know if the file exists or not - this can be checked with `exists()` call.
internal struct FileLocation {
    /// A directory that holds this file.
    let directory: DirectoryProtocol
    /// Relative path to the file within `directory`.
    let path: String

    /// Determines if file at this location exists.
    /// - Returns: `true` if it exists
    func exists() -> Bool {
        directory.fileExists(at: path)
    }

    /// Copies file from this location to another location.
    /// - Parameter otherLocation: target location for copying the file.
    func copy(to otherLocation: FileLocation) throws {
        try directory.copyFile(at: path, to: otherLocation.directory, at: otherLocation.path)
    }
}
