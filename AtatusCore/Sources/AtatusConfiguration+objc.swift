/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; renamed `clientToken` to
// `licenseKey`; rebranded the `dd` name to `Atatus` in comments and docs; scrubbed the remaining
// `dd` name to `dd` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

@objc(ATSite)
@objcMembers
@_spi(objc)
public final class objc_AtatusSite: NSObject {
    internal let sdkSite: AtatusSite

    internal init(sdkSite: AtatusSite) {
        self.sdkSite = sdkSite
    }

    // MARK: - Public

    // ATCHG: Replaced the nine dd region accessors with the single Atatus site,
    // matching the single `ATATUS` entry in Android's `AtatusSite` enum.
    public static func atatus() -> objc_AtatusSite { .init(sdkSite: .atatus) }
    // ATCHG: End
}

@objc(ATBatchSize)
@_spi(objc)
public enum objc_BatchSize: Int {
    case small
    case medium
    case large

    internal var swiftType: Atatus.Configuration.BatchSize {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }

    internal init(swiftType: Atatus.Configuration.BatchSize) {
        switch swiftType {
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        }
    }
}

@objc(ATUploadFrequency)
@_spi(objc)
public enum objc_UploadFrequency: Int {
    case frequent
    case average
    case rare

    internal var swiftType: Atatus.Configuration.UploadFrequency {
        switch self {
        case .frequent: return .frequent
        case .average: return .average
        case .rare: return .rare
        }
    }

    internal init(swiftType: Atatus.Configuration.UploadFrequency) {
        switch swiftType {
        case .frequent: self = .frequent
        case .average: self = .average
        case .rare: self = .rare
        }
    }
}

@objc(ATBatchProcessingLevel)
@_spi(objc)
public enum objc_BatchProcessingLevel: Int {
    case low
    case medium
    case high

    internal var swiftType: Atatus.Configuration.BatchProcessingLevel {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }

    internal init(swiftType: Atatus.Configuration.BatchProcessingLevel) {
        switch swiftType {
        case .low: self = .low
        case .medium: self = .medium
        case .high: self = .high
        }
    }
}

@objc(ATDataEncryption)
@_spi(objc)
public protocol objc_DataEncryption: AnyObject {
    /// Encrypts given `Data` with user-chosen encryption.
    ///
    /// - Parameter data: Data to encrypt.
    /// - Returns: The encrypted data.
    func encrypt(data: Data) throws -> Data

    /// Decrypts given `Data` with user-chosen encryption.
    ///
    /// Beware that data to decrypt could be encrypted in a previous
    /// app launch, so implementation should be aware of the case when decryption could
    /// fail (for example, key used for encryption is different from key used for decryption, if
    /// they are unique for every app launch).
    ///
    /// - Parameter data: Data to decrypt.
    /// - Returns: The decrypted data.
    func decrypt(data: Data) throws -> Data
}

internal struct ATDataEncryptionBridge: DataEncryption {
    let objcEncryption: objc_DataEncryption

    func encrypt(data: Data) throws -> Data {
        return try objcEncryption.encrypt(data: data)
    }

    func decrypt(data: Data) throws -> Data {
        return try objcEncryption.decrypt(data: data)
    }
}

@objc(ATServerDateProvider)
@_spi(objc)
public protocol objc_ServerDateProvider: AnyObject {
    /// Start the clock synchronisation with NTP server.
    ///
    /// Calls the `completion` by passing it the server time offset when the synchronization succeeds or`nil` if it fails.
    func synchronize(update: @escaping (TimeInterval) -> Void)
}

internal struct ATServerDateProviderBridge: ServerDateProvider {
    let objcProvider: objc_ServerDateProvider

    func synchronize(update: @escaping (TimeInterval) -> Void) {
        objcProvider.synchronize(update: update)
    }
}

@objc(ATConfiguration)
@objcMembers
@_spi(objc)
public final class objc_Configuration: NSObject {
    internal var sdkConfiguration: Atatus.Configuration

    /// Either the RUM client token (which supports RUM, Logging and APM) or regular client token, only for Logging and APM.
    public var licenseKey: String {
        get { sdkConfiguration.licenseKey }
        set { sdkConfiguration.licenseKey = newValue }
    }

    /// The environment name which will be sent to Atatus. This can be used
    /// To filter events on different environments (e.g. "staging" or "production").
    public var env: String {
        get { sdkConfiguration.env }
        set { sdkConfiguration.env = newValue }
    }

    /// The Atatus server site where data is sent.
    ///
    /// Default value is `.atatus`.
    public var site: objc_AtatusSite {
        get { objc_AtatusSite(sdkSite: sdkConfiguration.site) }
        set { sdkConfiguration.site = newValue.sdkSite }
    }

    /// The service name associated with data send to Atatus.
    ///
    /// Default value is set to application bundle identifier.
    public var service: String? {
        get { sdkConfiguration.service }
        set { sdkConfiguration.service = newValue }
    }

    /// The application version used for Unified Service Tagging.
    ///
    /// If not provided, the SDK will use the version from the application's Info.plist
    /// (`CFBundleShortVersionString` or `CFBundleVersion`).
    public var version: String? {
        get { sdkConfiguration.version }
        set { sdkConfiguration.version = newValue }
    }

    /// The preferred size of batched data uploaded to Atatus servers.
    /// This value impacts the size and number of requests performed by the SDK.
    ///
    /// `.medium` by default.
    public var batchSize: objc_BatchSize {
        get { objc_BatchSize(swiftType: sdkConfiguration.batchSize) }
        set { sdkConfiguration.batchSize = newValue.swiftType }
    }

    /// The preferred frequency of uploading data to Atatus servers.
    /// This value impacts the frequency of performing network requests by the SDK.
    ///
    /// `.average` by default.
    public var uploadFrequency: objc_UploadFrequency {
        get { objc_UploadFrequency(swiftType: sdkConfiguration.uploadFrequency) }
        set { sdkConfiguration.uploadFrequency = newValue.swiftType }
    }

    /// 
    public var batchProcessingLevel: objc_BatchProcessingLevel {
        get { objc_BatchProcessingLevel(swiftType: sdkConfiguration.batchProcessingLevel) }
        set { sdkConfiguration.batchProcessingLevel = newValue.swiftType }
    }

    /// Proxy configuration attributes.
    /// This can be used to a enable a custom proxy for uploading tracked data to Atatus's intake.
    public var proxyConfiguration: [AnyHashable: Any]? {
        get { sdkConfiguration.proxyConfiguration }
        set { sdkConfiguration.proxyConfiguration = newValue }
    }

    /// Sets Data encryption to use for on-disk data persistency by providing an object
    /// complying with `DataEncryption` protocol.
    public func setEncryption(_ encryption: objc_DataEncryption) {
        sdkConfiguration.encryption = ATDataEncryptionBridge(objcEncryption: encryption)
    }

    /// A custom NTP synchronization interface.
    ///
    /// By default, the Atatus SDK synchronizes with dedicated NTP pools provided by the
    /// https://www.ntppool.org/ . Using different pools or setting a no-op `ServerDateProvider`
    /// implementation will result in desynchronization of the SDK instance and the Atatus servers.
    /// This can lead to significant time shift in RUM sessions or distributed traces.
    public func setServerDateProvider(_ serverDateProvider: objc_ServerDateProvider) {
        sdkConfiguration.serverDateProvider = ATServerDateProviderBridge(objcProvider: serverDateProvider)
    }

    /// The bundle object that contains the current executable.
    public var bundle: Bundle {
        get { sdkConfiguration.bundle }
        set { sdkConfiguration.bundle = newValue }
    }

    /// Sets additional configuration attributes.
    /// This can be used to tweak internal features of the SDK and shouldn't be considered as a part of public API.
    public var additionalConfiguration: [String: Any] {
        get { sdkConfiguration._internal.additionalConfiguration }
        set { sdkConfiguration._internal_mutation { $0.additionalConfiguration = newValue } }
    }

    /// Flag that determines if UIApplication methods [`beginBackgroundTask(expirationHandler:)`](https://developer.apple.com/documentation/uikit/uiapplication/1623031-beginbackgroundtaskwithexpiratio) and [`endBackgroundTask:`](https://developer.apple.com/documentation/uikit/uiapplication/1622970-endbackgroundtask)
    /// are utilized to perform background uploads. It may extend the amount of time the app is operating in background by 30 seconds.
    ///
    /// Tasks are normally stopped when there's nothing to upload or when encountering any upload blocker such us no internet connection or low battery.
    ///
    /// `false` by default.
    public var backgroundTasksEnabled: Bool {
        get { sdkConfiguration.backgroundTasksEnabled }
        set { sdkConfiguration.backgroundTasksEnabled = newValue }
    }

    /// Creates a Atatus SDK Configuration object.
    ///
    /// - Parameters:
    ///   - licenseKey:    Either the RUM client token (which supports RUM, Logging and APM) or regular client token,
    ///                     only for Logging and APM.
    ///
    ///   - env:    The environment name which will be sent to Atatus. This can be used
    ///             To filter events on different environments (e.g. "staging" or "production").
    public init(licenseKey: String, env: String) {
        sdkConfiguration = .init(licenseKey: licenseKey, env: env)
    }
}
