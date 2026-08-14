/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `clientToken` to `licenseKey`; rebranded the `dd` name to
// `Atatus` in comments and docs; scrubbed the remaining `dd` name to `dd` in comments and docs;
// rebranded the licence header.

import Foundation
import AtatusInternal

@_exported import class AtatusInternal.CoreRegistry
@_exported import class AtatusInternal.HTTPHeadersWriter
@_exported import class AtatusInternal.B3HTTPHeadersWriter
@_exported import class AtatusInternal.W3CHTTPHeadersWriter

extension Atatus {
    /// Configuration of Atatus SDK.
    public struct Configuration {
        /// Defines the Atatus SDK policy when batching data together before uploading it to Atatus servers.
        /// Smaller batches mean smaller but more network requests, whereas larger batches mean fewer but larger network requests.
        public enum BatchSize: CaseIterable {
            /// Prefer small sized data batches.
            case small
            /// Prefer medium sized data batches.
            case medium
            /// Prefer large sized data batches.
            case large
        }

        /// Defines the frequency at which Atatus SDK will try to upload data batches.
        public enum UploadFrequency: CaseIterable {
            /// Try to upload batched data frequently.
            case frequent
            /// Try to upload batched data with a medium frequency.
            case average
            /// Try to upload batched data rarely.
            case rare
        }

        /// Defines the maximum amount of batches processed sequentially without a delay within one reading/uploading cycle.
        public enum BatchProcessingLevel: CaseIterable {
            case low
            case medium
            case high

            var maxBatchesPerUpload: Int {
                switch self {
                case .low:
                    return 5
                case .medium:
                    return 20
                case .high:
                    return 100
                }
            }
        }

        /// Either the RUM client token (which supports RUM, Logging and APM) or regular client token, only for Logging and APM.
        public var licenseKey: String

        /// The environment name which will be sent to Atatus. This can be used
        /// To filter events on different environments (e.g. "staging" or "production").
        public var env: String

        /// The Atatus server site where data is sent.
        ///
        /// Default value is `.atatus`. // ATCHG: single Atatus site replaces the dd regions
        public var site: AtatusSite

        // ATCHG: Added `serverUrl`, matching `Configuration.Builder.setServerUrl()` in the Atatus
        // Android agent, so an on-premise intake, a proxy or a local tunnel can be targeted.
        /// Sends all the data to a custom intake instead of the ``site`` one.
        ///
        /// The value must be a base url without any path (e.g. `https://rum.example.com`); each
        /// feature appends its own path to it (`v1/ios/rum`, `v1/ios/logs`, `v1/ios/spans`,
        /// `v1/ios/replay`). Trailing slashes are ignored.
        ///
        /// A feature level custom intake url (e.g. `RUM.Configuration.customEndpoint`) expects a
        /// full url and takes precedence over this value.
        ///
        /// `nil` by default, meaning the ``site`` intake is used.
        public var serverUrl: String?
        // ATCHG: End

        /// The service name associated with data send to Atatus.
        ///
        /// Default value is set to application bundle identifier.
        public var service: String?

        /// The application version used for Unified Service Tagging.
        ///
        /// If not provided, the SDK will use the version from the application's Info.plist
        /// (`CFBundleShortVersionString` or `CFBundleVersion`).
        public var version: String?

        /// The preferred size of batched data uploaded to Atatus servers.
        /// This value impacts the size and number of requests performed by the SDK.
        ///
        /// `.medium` by default.
        public var batchSize: BatchSize

        /// The preferred frequency of uploading data to Atatus servers.
        /// This value impacts the frequency of performing network requests by the SDK.
        ///
        /// `.average` by default.
        public var uploadFrequency: UploadFrequency

        /// Proxy configuration attributes.
        /// This can be used to a enable a custom proxy for uploading tracked data to Atatus's intake.
        ///
        /// Ref.: https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411499-connectionproxydictionary
        public var proxyConfiguration: [AnyHashable: Any]?

        /// SeData encryption to use for on-disk data persistency by providing an object
        /// complying with `DataEncryption` protocol.
        public var encryption: DataEncryption?

        /// A custom NTP synchronization interface.
        ///
        /// By default, the Atatus SDK synchronizes with dedicated NTP pools provided by the
        /// https://www.ntppool.org/ . Using different pools or setting a no-op `ServerDateProvider`
        /// implementation will result in desynchronization of the SDK instance and the Atatus servers.
        /// This can lead to significant time shift in RUM sessions or distributed traces.
        public var serverDateProvider: ServerDateProvider

        /// The bundle object that contains the current executable.
        public var bundle: Bundle

        /// Batch provessing level, defining the maximum number of batches processed sequencially without a delay within one reading/uploading cycle.
        ///
        /// `.medium` by default.
        public var batchProcessingLevel: BatchProcessingLevel

        /// Flag that determines if UIApplication methods [`beginBackgroundTask(expirationHandler:)`](https://developer.apple.com/documentation/uikit/uiapplication/1623031-beginbackgroundtaskwithexpiratio) and [`endBackgroundTask:`](https://developer.apple.com/documentation/uikit/uiapplication/1622970-endbackgroundtask)
        /// are utilized to perform background uploads. It may extend the amount of time the app is operating in background by 30 seconds.
        ///
        /// Tasks are normally stopped when there's nothing to upload or when encountering any upload blocker such us no internet connection or low battery.
        ///
        /// `false` by default.
        public var backgroundTasksEnabled: Bool

        /// Creates a Atatus SDK Configuration object.
        ///
        /// - Parameters:
        ///   - licenseKey:                Either the RUM client token (which supports RUM, Logging and APM) or regular client token,
        ///                                 only for Logging and APM.
        ///
        ///   - env:                        The environment name which will be sent to Atatus. This can be used
        ///                                 To filter events on different environments (e.g. "staging" or "production").
        ///
        ///   - site:                       Atatus site endpoint, default value is `.atatus`.
        ///
        ///   - serverUrl:                  ATCHG: A custom intake base url (no path) replacing the `site` one for
        ///                                 every feature, e.g. `https://rum.example.com`. Each feature appends
        ///                                 its own path to it. `nil` by default, meaning the `site` intake is used.
        ///
        ///   - service:                    The service name associated with data send to Atatus.
        ///                                 Default value is set to application bundle identifier.
        ///
        ///   - version:                    The application version used for Unified Service Tagging.
        ///                                 If not provided, the SDK will use the version from the application's Info.plist
        ///                                 (`CFBundleShortVersionString` or `CFBundleVersion`).
        ///
        ///   - bundle:                     The bundle object that contains the current executable.
        ///
        ///   - batchSize:                  The preferred size of batched data uploaded to Atatus servers.
        ///                                 This value impacts the size and number of requests performed by the SDK.
        ///                                 `.medium` by default.
        ///
        ///   - uploadFrequency:            The preferred frequency of uploading data to Atatus servers.
        ///                                 This value impacts the frequency of performing network requests by the SDK.
        ///                                 `.average` by default.
        ///
        ///   - proxyConfiguration:         A proxy configuration attributes.
        ///                                 This can be used to a enable a custom proxy for uploading tracked data to Atatus's intake.
        ///
        ///   - encryption:                 Data encryption to use for on-disk data persistency by providing an object
        ///                                 complying with `DataEncryption` protocol.
        ///
        ///   - serverDateProvider:         A custom NTP synchronization interface.
        ///                                 By default, the Atatus SDK synchronizes with dedicated NTP pools provided by the
        ///                                 https://www.ntppool.org/ . Using different pools or setting a no-op `ServerDateProvider`
        ///                                 implementation will result in desynchronization of the SDK instance and the Atatus servers.
        ///                                 This can lead to significant time shift in RUM sessions or distributed traces.
        ///   - backgroundTasksEnabled:     A flag that determines if `UIApplication` methods
        ///                                 `beginBackgroundTask(expirationHandler:)` and `endBackgroundTask:`
        ///                                 are used to perform background uploads.
        ///                                 It may extend the amount of time the app is operating in background by 30 seconds.
        ///                                 Tasks are normally stopped when there's nothing to upload or when encountering
        ///                                 any upload blocker such us no internet connection or low battery.
        ///                                 By default it's set to `false`.
        public init(
            licenseKey: String,
            env: String,
            site: AtatusSite = .atatus, // ATCHG: default site is the Atatus intake
            serverUrl: String? = nil, // ATCHG: no custom intake by default, the site endpoint is used
            service: String? = nil,
            version: String? = nil,
            bundle: Bundle = .main,
            batchSize: BatchSize = .medium,
            uploadFrequency: UploadFrequency = .average,
            proxyConfiguration: [AnyHashable: Any]? = nil,
            encryption: DataEncryption? = nil,
            serverDateProvider: ServerDateProvider? = nil,
            batchProcessingLevel: BatchProcessingLevel = .medium,
            backgroundTasksEnabled: Bool = false
        ) {
            self.licenseKey = licenseKey
            self.env = env
            self.site = site
            self.serverUrl = serverUrl // ATCHG: custom intake base url
            self.service = service
            self.version = version
            self.bundle = bundle
            self.batchSize = batchSize
            self.uploadFrequency = uploadFrequency
            self.proxyConfiguration = proxyConfiguration
            self.encryption = encryption
            self.serverDateProvider = serverDateProvider ?? AtatusNTPDateProvider()
            self.batchProcessingLevel = batchProcessingLevel
            self.backgroundTasksEnabled = backgroundTasksEnabled
        }

        // MARK: - Internal

        /// Obtains OS directory where SDK creates its root folder.
        /// All instances of the SDK use the same root folder, but each creates its own subdirectory.
        internal var systemDirectory: () throws -> Directory = { try Directory.cache() }

        /// Default process information.
        internal var processInfo: ProcessInfo = .processInfo

        /// Sets additional configuration attributes.
        /// This can be used to tweak internal features of the SDK.
        internal var additionalConfiguration: [String: Any] = [:]

        /// Default date provider used by the SDK and all products.
        internal var dateProvider: DateProvider = SystemDateProvider()

        /// Creates `HTTPClient` with given proxy configuration attributes.
        internal var httpClientFactory: ([AnyHashable: Any]?) -> HTTPClient = { proxyConfiguration in
            URLSessionClient(proxyConfiguration: proxyConfiguration)
        }

        /// The default notification center used for subscribing to app lifecycle events and system notifications.
        internal var notificationCenter: NotificationCenter = .default

        /// The default app launch handler for tracking application startup time.
        internal var appLaunchHandler: AppLaunchHandling = AppLaunchHandler.shared

        /// The default application state provider for accessing [application state](https://developer.apple.com/documentation/uikit/uiapplication/state).
        internal var appStateProvider: AppStateProvider = DefaultAppStateProvider()
    }
}
