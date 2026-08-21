/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; renamed `dd*` members to `at*`; renamed `clientToken` to `licenseKey`; renamed the build `variant`
// to `appName`; repointed the intake host at the Atatus site; rebranded the `dd` name to `Atatus` in
// comments and docs; rebranded the licence header.

import Foundation

public struct AtatusContext {
    // MARK: - Atatus Specific

    /// [Atatus Site](https://www.atatus.com/docs/) for data uploads. It can be `nil` in V1
    /// if the SDK is configured using deprecated APIs:
    /// `set(logsEndpoint:)`, `set(tracesEndpoint:)` and `set(rumEndpoint:)`.
    public let site: AtatusSite

    // ATCHG: Added `serverUrl`, matching `AtatusContext.serverUrl` in the Atatus Android agent.
    /// A custom intake base url (no path) overriding the ``site`` one when set.
    ///
    /// Set through `Atatus.Configuration.serverUrl`. Use ``intakeEndpoint`` rather than reading
    /// this directly — it applies the fallbacks.
    public let serverUrl: String?
    // ATCHG: End

    /// The client token allowing for data uploads to [Atatus Site](https://www.atatus.com/docs/).
    public let licenseKey: String

    /// The name of the service that data is generated from. Used for [Unified Service Tagging](https://www.atatus.com/docs/).
    public let service: String

    /// The name of the environment that data is generated from. Used for [Unified Service Tagging](https://www.atatus.com/docs/).
    public let env: String

    /// The version of the application that data is generated from. Used for [Unified Service Tagging](https://www.atatus.com/docs/).
    public var version: String {
        didSet {
            guard version != oldValue else {
                return
            }
            version = version.sanitizedToDDTags()
            atTags = buildDDTags()
        }
    }

    /// The build number of the application that data is generated from.
    public let buildNumber: String

    /// The id of the build, specifically for cross platform frameworks
    public let buildId: String?

    /// The name of the application (display name / flavor), equivalent to Android's "Flavor".
    /// Only set by cross platform SDKs.
    ///
    /// The `app_name` query item on intake requests falls back to ``service`` when this is nil, so
    /// a native app still sends one — the intake rejects a request without it with 400 "App name is
    /// missing!". The fallback is applied in the request builders rather than here, so it reaches
    /// the URL without adding an `app_name` tag to every event's `atTags`.
    /// // ATCHG: renamed from `variant` to `appName`
    public let appName: String?

    /// Denotes the mobile application's platform, such as `"ios"` or `"flutter"` that data is generated from.
    ///  - See: Atatus [Reserved Attributes](https://www.atatus.com/docs/).
    public let source: String

    /// Denotes the source type for  crashes. This is used for platforms that provide additional symbolication steps for native crashes.
    public let nativeSourceOverride: String?

    /// The version of Atatus iOS SDK.
    public let sdkVersion: String

    /// The name of [CI Visibility](https://www.atatus.com/docs/) origin.
    /// It is only set if the SDK is running with a context passed from [Swift Tests](https://www.atatus.com/docs/) library.
    public let ciAppOrigin: String?

    /// Interval between device and server time.
    ///
    /// The value can change as the device continue to sync with the server.
    public var serverTimeOffset: TimeInterval = .zero

    /// Cached Atatus tags to send in the events. Recomputed when `version` changes.
    public private(set) var atTags: String = ""

    // MARK: - Application Specific

    /// The name of the application, read from `Info.plist` (`CFBundleExecutable`).
    public let applicationName: String

    /// The bundle identifier, read from `Info.plist` (`CFBundleIdentifier`).
    public let applicationBundleIdentifier: String

    /// The type of the bundle running the SDK.
    public let applicationBundleType: BundleType

    /// Date of SDK initialization measured in device time (without NTP correction).
    public let sdkInitDate: Date

    /// Current device information.
    public var device: DeviceInfo

    /// Operating System information.
    public let os: OperatingSystem

    /// Current locale information.
    public var localeInfo: LocaleInfo

    /// Current user information.
    public var userInfo: UserInfo?

    /// Current user information.
    public var accountInfo: AccountInfo?

    /// The user's consent to data collection
    public var trackingConsent: TrackingConsent = .pending

    /// Application launch info.
    public var launchInfo: LaunchInfo

    /// Provides the history of app foreground / background states.
    public var applicationStateHistory: AppStateHistory

    // MARK: - Device Specific

    /// Network information.
    ///
    /// Represents the current state of the device network connectivity and interface.
    /// The value can be `unknown` if the network interface is not available or if it has not
    /// yet been evaluated.
    public var networkConnectionInfo: NetworkConnectionInfo?

    /// Carrier information.
    ///
    /// Represents the current telephony service info of the device.
    /// This value can be `nil` of no service is currently registered, or if the device does
    /// not support telephony services.
    public var carrierInfo: CarrierInfo?

    /// The current mobile device battery status.
    ///
    /// This value can be `nil` of the current device battery interface is not available.
    public var batteryStatus: BatteryStatus?

    /// The current brightness status.
    public var brightnessLevel: BrightnessLevel?

    /// `true` if the Low Power Mode is enabled.
    public var isLowPowerModeEnabled = false

    /// Additional context that can set from `core` instance.
    private var additionalContext: [String: AdditionalContext] = [:]

    // swiftlint:disable function_default_parameter_at_end
    public init(
        site: AtatusSite,
        serverUrl: String? = nil, // ATCHG: Added the custom intake base url, `nil` unless configured
        licenseKey: String,
        service: String,
        env: String,
        version: String,
        buildNumber: String,
        buildId: String?,
        appName: String?,
        source: String,
        sdkVersion: String,
        ciAppOrigin: String?,
        serverTimeOffset: TimeInterval = .zero,
        applicationName: String,
        applicationBundleIdentifier: String,
        applicationBundleType: BundleType,
        sdkInitDate: Date,
        device: DeviceInfo,
        os: OperatingSystem,
        localeInfo: LocaleInfo,
        nativeSourceOverride: String? = nil,
        userInfo: UserInfo? = nil,
        accountInfo: AccountInfo? = nil,
        trackingConsent: TrackingConsent = .pending,
        launchInfo: LaunchInfo,
        applicationStateHistory: AppStateHistory,
        networkConnectionInfo: NetworkConnectionInfo? = nil,
        carrierInfo: CarrierInfo? = nil,
        batteryStatus: BatteryStatus? = nil,
        brightnessLevel: BrightnessLevel? = nil,
        isLowPowerModeEnabled: Bool = false,
        additionalContext: [String: AdditionalContext] = [:]
    ) {
        self.site = site
        self.serverUrl = serverUrl // ATCHG: Added the custom intake base url
        self.licenseKey = licenseKey
        self.service = service.sanitizedToDDTags()
        self.env = env.sanitizedToDDTags()
        self.version = version.sanitizedToDDTags()
        self.buildNumber = buildNumber
        self.buildId = buildId
        self.appName = appName?.sanitizedToDDTags()
        self.source = source
        self.sdkVersion = sdkVersion.sanitizedToDDTags()
        self.ciAppOrigin = ciAppOrigin
        self.serverTimeOffset = serverTimeOffset
        self.applicationName = applicationName
        self.applicationBundleIdentifier = applicationBundleIdentifier
        self.applicationBundleType = applicationBundleType
        self.sdkInitDate = sdkInitDate
        self.device = device
        self.os = os
        self.localeInfo = localeInfo
        self.nativeSourceOverride = nativeSourceOverride
        self.userInfo = userInfo
        self.accountInfo = accountInfo
        self.trackingConsent = trackingConsent
        self.launchInfo = launchInfo
        self.applicationStateHistory = applicationStateHistory
        self.networkConnectionInfo = networkConnectionInfo
        self.carrierInfo = carrierInfo
        self.batteryStatus = batteryStatus
        self.brightnessLevel = brightnessLevel
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.additionalContext = additionalContext
        self.atTags = buildDDTags()
    }
    // swiftlint:enable function_default_parameter_at_end

    private func buildDDTags() -> String {
        var result = "\(ATTag.service):\(service),\(ATTag.version):\(version),\(ATTag.sdkVersion):\(sdkVersion),\(ATTag.env):\(env)"
        if let appName {
            result += ",\(ATTag.appName):\(appName)"
        }
        return result
    }
}

// ATCHG: Added `intakeEndpoint` so every feature resolves its base url the same way, matching
// `val AtatusContext.intakeEndpoint` in the Atatus Android agent.
extension AtatusContext {
    /// The base url all intake requests are built from: the custom ``serverUrl`` when one was
    /// configured through `Atatus.Configuration.serverUrl`, the ``site`` intake endpoint otherwise.
    /// Never has a trailing slash.
    ///
    /// Features append their own path to it, e.g. `v1/ios/rum`, `v1/ios/logs`, `v1/ios/spans`,
    /// `v1/ios/replay`. A feature level custom intake url takes precedence over this value.
    public var intakeEndpoint: URL {
        AtatusSite.intakeEndpoint(serverUrl: serverUrl, site: site)
    }
}
// ATCHG: End

/// Defines an additional context value type associated to a key.
public protocol AdditionalContext {
    /// The additional context key.
    static var key: String { get }
}

extension AtatusContext {
    /// Gets an additional context value of `Context` type.
    ///
    /// - Parameter type: The additional context type.
    /// - Returns: The `Context` if found
    public func additionalContext<Context>(ofType type: Context.Type) -> Context? where Context: AdditionalContext {
        additionalContext[type.key] as? Context
    }

    /// Sets additional context to `AtatusContext`.
    ///
    /// This method only mutates the current instance. To propagate an additional context
    /// across the Atatus SDK, please use the ``AtatusCoreProtocol/set(context:)`` instead.
    ///
    /// - Parameters:
    ///   - context: The additional context to set.
    public mutating func set<Context>(additionalContext context: Context?) where Context: AdditionalContext {
        additionalContext[Context.key] = context
    }

    /// Removes additional context from `AtatusContext`.
    ///
    /// This method only mutates the current instance. To propagate an additional context
    /// across the Atatus SDK, please use the ``AtatusCoreProtocol/removeContext(ofType:)`` instead
    /// 
    /// - Parameters:
    ///   - type: The context's type to remove.
    public mutating func removeContext<Context>(ofType type: Context.Type) where Context: AdditionalContext {
        additionalContext[Context.key] = nil
    }
}

extension String {
    func sanitizedToDDTags() -> String {
        self.replacingOccurrences(of: "[,:]", with: "", options: .regularExpression)
    }
}
