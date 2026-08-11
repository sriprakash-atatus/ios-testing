/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; renamed `dd*` members to `at*`; repointed the intake host at the Atatus site; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// Describes current Atatus SDK context, so the app state information can be attached to
/// the crash report and retrieved back when the application is started again.
///
/// Note: as it gets saved along with the crash report during process interruption, it's good
/// to keep this data well-packed and as small as possible.
public struct CrashContext: Codable, Equatable {
    /// The Application Launch Date
    public var appLaunchDate: Date?

    /// Interval between device and server time.
    ///
    /// The value can change as the device continue to sync with the server.
    public let serverTimeOffset: TimeInterval

    /// The name of the service that data is generated from. Used for [Unified Service Tagging](https://www.atatus.com/docs/).
    public let service: String

    /// The name of the environment that data is generated from. Used for [Unified Service Tagging](https://www.atatus.com/docs/).
    public let env: String

    /// The version of the application that data is generated from. Used for [Unified Service Tagging](https://www.atatus.com/docs/).
    public let version: String

    /// The build number of the application that data is generated from.
    public let buildNumber: String

    /// Current device information.
    public let device: Device

    /// Operating System information.
    public let os: OperatingSystem

    /// The version of Atatus iOS SDK.
    public let sdkVersion: String

    /// Denotes the mobile application's platform, such as `"ios"` or `"flutter"` that data is generated from.
    ///  - See: Atatus [Reserved Attributes](https://www.atatus.com/docs/).
    public let source: String

    /// The user's consent to data collection
    public let trackingConsent: TrackingConsent

    /// Current user information.
    public let userInfo: UserInfo?

    /// Current account information
    public let accountInfo: AccountInfo?

    /// Network information.
    ///
    /// Represents the current state of the device network connectivity and interface.
    /// The value can be `unknown` if the network interface is not available or if it has not
    /// yet been evaluated.
    public let networkConnectionInfo: NetworkConnectionInfo?

    /// Carrier information.
    ///
    /// Represents the current telephony service info of the device.
    /// This value can be `nil` of no service is currently registered, or if the device does
    /// not support telephony services.
    public let carrierInfo: CarrierInfo?

    /// The last _"Is app in foreground?"_ information from crashed app process.
    public let lastIsAppInForeground: Bool

    /// The last RUM view in crashed app process.
    public var lastRUMViewEvent: RUMViewEvent?

    /// State of the last RUM session in crashed app process.
    public var lastRUMSessionState: RUMSessionState?

    /// Last global log attributes, set with Logs.addAttribute / Logs.removeAttribute
    public var lastLogAttributes: LogEventAttributes?

    /// Last global RUM attributes. It gets updated with adding or removing attributes on `RUMMonitor`.
    public var lastRUMAttributes: RUMEventAttributes?

    // MARK: - Initialization

    public init(
        serverTimeOffset: TimeInterval,
        service: String,
        env: String,
        version: String,
        buildNumber: String,
        device: Device,
        os: OperatingSystem,
        sdkVersion: String,
        source: String,
        trackingConsent: TrackingConsent,
        userInfo: UserInfo?,
        accountInfo: AccountInfo?,
        networkConnectionInfo: NetworkConnectionInfo?,
        carrierInfo: CarrierInfo?,
        lastIsAppInForeground: Bool,
        appLaunchDate: Date?,
        lastRUMViewEvent: RUMViewEvent?,
        lastRUMSessionState: RUMSessionState?,
        lastRUMAttributes: RUMEventAttributes?,
        lastLogAttributes: LogEventAttributes?
    ) {
        self.serverTimeOffset = serverTimeOffset
        self.service = service.sanitizedToDDTags()
        self.env = env.sanitizedToDDTags()
        self.version = version.sanitizedToDDTags()
        self.buildNumber = buildNumber
        self.device = device
        self.os = os
        self.sdkVersion = sdkVersion.sanitizedToDDTags()
        self.source = source
        self.trackingConsent = trackingConsent
        self.userInfo = userInfo
        self.accountInfo = accountInfo
        self.networkConnectionInfo = networkConnectionInfo
        self.carrierInfo = carrierInfo
        self.lastIsAppInForeground = lastIsAppInForeground
        self.appLaunchDate = appLaunchDate
        self.lastRUMViewEvent = lastRUMViewEvent
        self.lastRUMSessionState = lastRUMSessionState
        self.lastRUMAttributes = lastRUMAttributes
        self.lastLogAttributes = lastLogAttributes
    }

    public init(
        _ context: AtatusContext,
        lastRUMViewEvent: RUMViewEvent?,
        lastRUMSessionState: RUMSessionState?,
        lastRUMAttributes: RUMEventAttributes?,
        lastLogAttributes: LogEventAttributes?
    ) {
        self.serverTimeOffset = context.serverTimeOffset
        self.service = context.service
        self.env = context.env
        self.version = context.version
        self.buildNumber = context.buildNumber
        self.device = context.normalizedDevice()
        self.os = context.os
        self.sdkVersion = context.sdkVersion
        self.source = context.source
        self.trackingConsent = context.trackingConsent
        self.userInfo = context.userInfo
        self.accountInfo = context.accountInfo
        self.networkConnectionInfo = context.networkConnectionInfo
        self.carrierInfo = context.carrierInfo
        self.lastIsAppInForeground = context.applicationStateHistory.currentState.isRunningInForeground

        self.lastRUMViewEvent = lastRUMViewEvent
        self.lastRUMSessionState = lastRUMSessionState
        self.lastRUMAttributes = lastRUMAttributes
        self.lastLogAttributes = lastLogAttributes

        self.appLaunchDate = context.launchInfo.launchPhaseDates[.processLaunch]
    }

    public static func == (lhs: CrashContext, rhs: CrashContext) -> Bool {
        lhs.serverTimeOffset == rhs.serverTimeOffset &&
        lhs.service == rhs.service &&
        lhs.env == rhs.env &&
        lhs.version == rhs.version &&
        lhs.buildNumber == rhs.buildNumber &&
        lhs.source == rhs.source &&
        lhs.trackingConsent == rhs.trackingConsent &&
        lhs.networkConnectionInfo == rhs.networkConnectionInfo &&
        lhs.carrierInfo == rhs.carrierInfo &&
        lhs.lastIsAppInForeground == rhs.lastIsAppInForeground &&
        lhs.userInfo?.id == rhs.userInfo?.id &&
        lhs.userInfo?.name == rhs.userInfo?.name &&
        lhs.userInfo?.email == rhs.userInfo?.email &&
        lhs.accountInfo?.id == rhs.accountInfo?.id &&
        lhs.accountInfo?.name == rhs.accountInfo?.name &&
        lhs.appLaunchDate == rhs.appLaunchDate
    }
}

extension CrashContext {
    /// Atatus tags to send in the error events.
    public var atTags: String {
        "\(ATTag.service):\(service),\(ATTag.version):\(version),\(ATTag.sdkVersion):\(sdkVersion),\(ATTag.env):\(env)"
    }
}
