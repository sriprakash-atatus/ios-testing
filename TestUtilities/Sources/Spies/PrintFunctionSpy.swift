/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

// MARK: - Global Dependencies Mocks

/// Mock which can be used to intercept messages printed by `developerLogger` or
/// `userLogger` by overwriting `Atatus.consolePrint` function:
///
///     let printFunction = PrintFunctionMock()
///     consolePrint = printFunction.print
///
public class PrintFunctionSpy: @unchecked Sendable {
    @ReadWriteLock
    public private(set) var printedMessages: [String] = []

    public var printedMessage: String? { printedMessages.last }

    public init() { }

    @Sendable
    public func print(message: String, level: CoreLoggerLevel) {
        printedMessages.append(message)
    }

    public func reset() {
        printedMessages = []
    }
}
