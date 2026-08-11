/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; renamed
// `clientToken` to `licenseKey`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import Foundation
import AtatusInternal
import AtatusCore

/// Test info reads configuration from `Info.plist`.
///
/// The expected format is as follow:
///
///     <dict>
///         <key>AtatusConfiguration</key>
///         <dict>
///             <key>LicenseKey</key>
///             <string>$(CLIENT_TOKEN)</string>
///             <key>ApplicationID</key>
///             <string>$(RUM_APPLICATION_ID)</string>
///             <key>Environment</key>
///             <string>$(AT_ENV)</string>
///             <key>Site</key>
///             <string>$(AT_SITE)</string>
///         </dict>
///     </dict>
struct TestInfo {
    let licenseKey: String
    let applicationID: String
    let site: AtatusSite
    let env: String
}

extension TestInfo {
    init(bundle: Bundle = .main) throws {
        guard
            let obj = bundle.object(forInfoDictionaryKey: "AtatusConfiguration") as? [String: String],
            let licenseKey = obj["LicenseKey"],
            let applicationID = obj["ApplicationID"],
            let site = obj["Site"].flatMap(AtatusSite.init(rawValue:)),
            let env = obj["Environment"]
        else {
            throw ProgrammerError(description: "Missing required Info.plist keys")
        }

        self = .init(licenseKey: licenseKey, applicationID: applicationID, site: site, env: env)
    }
}

extension TestInfo {
    static var empty: Self {
        .init(
            licenseKey: "",
            applicationID: "",
            site: .atatus,
            env: "e2e"
        )
    }
}

extension Atatus.Configuration {
    static func e2e(info: TestInfo) -> Self {
        .init(
            licenseKey: info.licenseKey,
            env: info.env,
            site: info.site,
            uploadFrequency: .frequent
        )
    }
}
