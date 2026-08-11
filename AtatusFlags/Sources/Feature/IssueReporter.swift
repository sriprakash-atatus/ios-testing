/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

internal struct IssueReporter {
    let reportIssue: (_ message: String, _ file: StaticString, _ line: UInt) -> Void

    init(reportIssue: @escaping (_ message: String, _ file: StaticString, _ line: UInt) -> Void) {
        self.reportIssue = reportIssue
    }
}

extension IssueReporter {
    static var `default`: Self {
        `default`(isGracefulModeEnabled: true)
    }

    static func `default`(isGracefulModeEnabled: Bool) -> Self {
#if DEBUG
        isGracefulModeEnabled ? consolePrint : fatalError
#else
        coreLogger
#endif
    }

    private static let coreLogger = Self { message, _, _ in
        AT.logger.error(message)
    }

    private static let consolePrint = Self { message, _, _ in
        AtatusInternal.consolePrint("🔥 Atatus SDK usage error: \(message)", .error)
    }

    private static let fatalError = Self { message, file, line in
        Swift.fatalError(message, file: file, line: line)
    }
}

internal func reportIssue(
    _ message: @autoclosure () -> String,
    in core: (any AtatusCoreProtocol)?,
    file: StaticString = #file,
    line: UInt = #line
) {
    let issueReporter = core?.get(feature: FlagsFeature.self)?.issueReporter ?? .default
    issueReporter.reportIssue(message(), file, line)
}
