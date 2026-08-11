/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

extension OperatingSystem {
    /// Creates operating system info.
    ///
    /// - Parameters:
    ///   - name: Operating system name, e.g. Android, iOS
    ///   - version: Full operating system version, e.g. 8.1.1
    ///   - build: Operating system build number, e.g. 15D21
    public init(
        name: String,
        version: String,
        build: String?
    ) {
        self.name = name
        self.version = version
        self.versionMajor = version.split(separator: ".").first.map { String($0) } ?? version
        self.build = build
    }

#if !os(macOS)
    /// Creates operating system info based on device description.
    ///
    /// - Parameters:
    ///   - device: The device description.
    ///   - sysctl: Utilities around the `Darwin.sysctl` function.
    public init(
        device: _UIDevice = .dd.current,
        sysctl: SysctlProviding = Sysctl()
    ) {
        let build = try? sysctl.osBuild()

        self.init(
            name: device.systemName,
            version: device.systemVersion,
            build: build
        )
    }
#else
    /// Creates operating system info based on process information.
    ///
    /// - Parameters:
    ///   - processInfo: The current process information.
    ///   - sysctl: Utilities around the `Darwin.sysctl` function.
    public init(
        processInfo: ProcessInfo = .processInfo,
        sysctl: SysctlProviding = Sysctl()
    ) {
        let systemVersion = processInfo.operatingSystemVersion
        let build = (try? sysctl.osBuild()) ?? ""

        self.init(
            name: "macOS",
            version: "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)",
            build: build
        )
    }
#endif
}
