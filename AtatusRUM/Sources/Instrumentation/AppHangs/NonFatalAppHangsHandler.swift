/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

internal final class NonFatalAppHangsHandler: RUMCommandPublisher {
    /// Weak reference to RUM monitor for sending App Hang events.
    private(set) weak var subscriber: RUMCommandSubscriber?

    func publish(to subscriber: RUMCommandSubscriber) {
        self.subscriber = subscriber
    }

    func endHang(appHang: AppHang, duration: TimeInterval) {
        let command = RUMAddCurrentViewAppHangCommand(
            time: appHang.startDate,
            attributes: [:],
            message: AppHangsMonitor.Constants.appHangErrorMessage,
            type: AppHangsMonitor.Constants.appHangErrorType,
            stack: appHang.backtraceResult.stack,
            threads: appHang.backtraceResult.threads,
            binaryImages: appHang.backtraceResult.binaryImages,
            isStackTraceTruncated: appHang.backtraceResult.wasTruncated,
            hangDuration: duration
        )

        subscriber?.process(command: command)
    }
}

internal extension AppHang.BacktraceGenerationResult {
    var stack: String {
        switch self {
        case .succeeded(let backtrace): return backtrace.stack
        case .failed: return AppHangsMonitor.Constants.appHangStackGenerationFailedErrorMessage
        case .notAvailable: return AppHangsMonitor.Constants.appHangStackNotAvailableErrorMessage
        }
    }

    var threads: [ATThread]? {
        switch self {
        case .succeeded(let backtrace): return backtrace.threads
        case .failed, .notAvailable: return nil
        }
    }

    var binaryImages: [BinaryImage]? {
        switch self {
        case .succeeded(let backtrace): return backtrace.binaryImages
        case .failed, .notAvailable: return nil
        }
    }

    var wasTruncated: Bool? {
        switch self {
        case .succeeded(let backtrace): return backtrace.wasTruncated
        case .failed, .notAvailable: return nil
        }
    }
}
