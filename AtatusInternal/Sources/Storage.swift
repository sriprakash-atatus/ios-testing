/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// A Atatus  protocol that provides persistence related information.
public protocol Storage {
    /// Returns the most recent modified file before a given date.
    /// - Parameter before: The date to compare the last modification date of files.
    /// - Returns: The most recent modified file or `nil` if no files were modified before the given date.
    func mostRecentModifiedFileAt(before: Date) throws -> Date?
}

internal struct CoreStorage: Storage {
    /// A weak core reference.
    private weak var core: AtatusCoreProtocol?

    /// Creates a Storage associated with a core instance.
    ///
    /// The `CoreStorage` keeps a weak reference
    /// to the provided core.
    ///
    /// - Parameter core: The core instance.
    init(core: AtatusCoreProtocol) {
        self.core = core
    }

    /// Returns the most recent modified file before a given date from the core.
    /// - Parameter before: The date to compare the last modification date of files.
    /// - Returns: The most recent modified file or `nil` if no files were modified before the given date.
    func mostRecentModifiedFileAt(before: Date) throws -> Date? {
        try core?.mostRecentModifiedFileAt(before: before)
    }
}
