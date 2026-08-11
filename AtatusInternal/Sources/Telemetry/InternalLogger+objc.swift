/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the licence header.

import Foundation

@objc(ATInternalLogger)
@objcMembers
@_spi(objc)
public final class objc_InternalLogger: NSObject {
    /// Function printing `String` content to console. Intended to be used only by SDK components.
    @objc
    public static func consolePrint(_ message: String, _ level: objc_CoreLoggerLevel) {
        let coreLoggerLevel: CoreLoggerLevel = switch level {
        case .none: .debug
        case .debug: .debug
        case .warn: .warn
        case .error: .error
        case .critical: .critical
        }
        AtatusInternal.consolePrint(message, coreLoggerLevel)
    }

    @objc
    public static func telemetryDebug(id: String, message: String) {
        CoreRegistry.default.telemetry.debug(id: id, message: message)
    }

    @objc
    public static func telemetryError(id: String, message: String, kind: String?, stack: String?) {
        CoreRegistry.default.telemetry.error(id: id, message: message, kind: kind ?? "", stack: stack ?? "")
    }
}
