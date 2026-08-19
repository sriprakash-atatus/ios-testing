/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed `clientToken` to
// `licenseKey`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence
// header.

import Foundation

internal struct Environment {
    /// Launch arguments shared between UITests and Example targets.
    struct Argument {
        static let isRunningUnitTests       = "IS_RUNNING_UNIT_TESTS"
        static let isRunningUITests         = "IS_RUNNING_UI_TESTS"
    }

    struct InfoPlistKey {
        static let licenseKey      = "AtatusClientToken"
        static let rumApplicationID = "RUMApplicationID"

        static let customLogsURL    = "CustomLogsURL"
        static let customTraceURL   = "CustomTraceURL"
        static let customRUMURL     = "CustomRUMURL"
    }

    // MARK: - Launch Arguments

    static func isRunningUnitTests() -> Bool {
        return ProcessInfo.processInfo.arguments.contains(Argument.isRunningUnitTests)
    }

    static func isRunningUITests() -> Bool {
        return ProcessInfo.processInfo.arguments.contains(Argument.isRunningUITests)
    }

    /// If running `Example` in interactive, debug mode (launching it with 'Run' in Xcode or by tapping on the app icon).
    static func isRunningInteractive() -> Bool {
        return !isRunningUITests() && !isRunningUnitTests()
    }

    // MARK: - Info.plist

    static func readClientToken() -> String {
        guard let licenseKey = Bundle.main.infoDictionary?[InfoPlistKey.licenseKey] as? String, !licenseKey.isEmpty else {
            fatalError("""
            ✋⛔️ Cannot read `\(InfoPlistKey.licenseKey)` from `Info.plist` dictionary.
            Please update `Atatus.xcconfig` in the repository root with your own
            client token obtained on atatus.com.
            You might need to run `Product > Clean Build Folder` before retrying.
            """)
        }
        return licenseKey
    }

    static func readRUMApplicationID() -> String {
        guard let rumApplicationID = Bundle.main.infoDictionary![InfoPlistKey.rumApplicationID] as? String, !rumApplicationID.isEmpty else {
            fatalError("""
            ✋⛔️ Cannot read `\(InfoPlistKey.rumApplicationID)` from `Info.plist` dictionary.
            Please update `Atatus.xcconfig` in the repository root with your own
            RUM application id obtained on atatus.com.
            You might need to run `Product > Clean Build Folder` before retrying.
            """)
        }
        return rumApplicationID
    }

    static func readCustomLogsURL() -> URL? {
        if let customLogsURL = Bundle.main.infoDictionary![InfoPlistKey.customLogsURL] as? String,
           !customLogsURL.isEmpty {
            return URL(string: "https://\(customLogsURL)")
        }
        return nil
    }

    static func readCustomTraceURL() -> URL? {
        if let customTraceURL = Bundle.main.infoDictionary![InfoPlistKey.customTraceURL] as? String,
           !customTraceURL.isEmpty {
            return URL(string: "https://\(customTraceURL)")
        }
        return nil
    }

    static func readCustomRUMURL() -> URL? {
        if let customRUMURL = Bundle.main.infoDictionary![InfoPlistKey.customRUMURL] as? String,
           !customRUMURL.isEmpty {
            return URL(string: "https://\(customRUMURL)")
        }
        return nil
    }
}
