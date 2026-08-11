/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// A snapshot of all running threads in the current process. It focuses on tracing back from the error point (where backtrace
/// generation started) to the root cause or the origin of the problem.
///
/// - Unlike `ATCrashReport`, the backtrace report can be generated on-demand without the actual crash being triggered.
/// - Like in `ATCrashReport`, threads and stacks information in `BacktraceReport` follows the format compatible with Atatus symbolication.
public struct BacktraceReport: Codable {
    /// The stack trace of the thread for which the backtrace is generated.
    public let stack: String
    /// Represents all threads currently running in the process.
    public let threads: [ATThread]
    /// A list of binary images referenced from all stack traces.
    public let binaryImages: [BinaryImage]
    /// Indicates whether any stack trace information in `threads` was truncated due to stack trace minimization.
    public let wasTruncated: Bool

    /// Initializes a new instance of `BacktraceReport`.
    /// - Parameters:
    ///   - stack: The stack trace of the thread.
    ///   - threads: All threads currently running in the process.
    ///   - binaryImages: A list of binary images referenced from all stack traces.
    ///   - wasTruncated: Indicates whether stack trace information was truncated.
    public init(
        stack: String,
        threads: [ATThread],
        binaryImages: [BinaryImage],
        wasTruncated: Bool
    ) {
        self.stack = stack
        self.threads = threads
        self.binaryImages = binaryImages
        self.wasTruncated = wasTruncated
    }
}
