/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`, `ddLogs` -> `AtatusLogs`, `ddTrace` -> `AtatusTrace`; renamed `dd*`
// types to `Atatus*`; renamed `clientToken` to `licenseKey`; renamed the build `variant` to `appName`;
// renamed the `ddsource` / `ddtags` query parameters to `atatus_source` / `atatustags`; renamed
// `com.ddhq.*` identifiers to `com.atatus.*`; rebranded the `dd` name to `Atatus` in comments and
// docs; rebranded the licence header.

import XCTest
import TestUtilities

@testable import AtatusInternal
@testable import AtatusLogs
@testable import AtatusTrace
@testable import AtatusCore

class AtatusTests: XCTestCase {
    private var printFunction: PrintFunctionSpy! // swiftlint:disable:this implicitly_unwrapped_optional
    private var defaultConfig = Atatus.Configuration(licenseKey: "abc-123", env: "tests")

    override func setUp() {
        super.setUp()

        XCTAssertFalse(Atatus.isInitialized())
        printFunction = PrintFunctionSpy()
        consolePrint = printFunction.print
    }

    override func tearDown() {
        consolePrint = { message, _ in print(message) }
        printFunction = nil
        XCTAssertFalse(Atatus.isInitialized())
        super.tearDown()
    }

    // MARK: - Initializing with different configurations

    func testDefaultConfiguration() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            bundleIdentifier: "test",
            CFBundleShortVersionString: "1.0.0",
            CFBundleExecutable: "Test"
        )

        XCTAssertEqual(configuration.batchSize, .medium)
        XCTAssertEqual(configuration.uploadFrequency, .average)
        XCTAssertEqual(configuration.additionalConfiguration.count, 0)
        XCTAssertNil(configuration.encryption)
        XCTAssertTrue(configuration.serverDateProvider is AtatusNTPDateProvider)

        Atatus.initialize(
            with: configuration,
            trackingConsent: .granted
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let urlSessionClient = try XCTUnwrap(core.httpClient as? URLSessionClient)
        XCTAssertTrue(core.dateProvider is SystemDateProvider)
        XCTAssertNil(urlSessionClient.session.configuration.connectionProxyDictionary)
        XCTAssertNil(core.encryption)

        let context = core.contextProvider.read()
        XCTAssertEqual(context.licenseKey, "abc-123")
        XCTAssertEqual(context.env, "tests")
        XCTAssertEqual(context.site, .atatus)
        XCTAssertEqual(context.service, "test")
        XCTAssertEqual(context.version, "1.0.0")
        XCTAssertEqual(context.sdkVersion, __sdkVersion)
        XCTAssertEqual(context.applicationName, "Test")
        // ATCHG: A native app now falls back to `service`, so the intake never receives an empty
        // `app_name` — it answers 400 "App name is missing!" to those.
        XCTAssertEqual(context.appName, "test")
        XCTAssertEqual(context.source, "ios")
        XCTAssertEqual(context.applicationBundleIdentifier, "test")
        XCTAssertEqual(context.trackingConsent, .granted)
    }

    func testAdvancedConfiguration() throws {
        var configuration = defaultConfig

        configuration.service = "service-name"
        configuration.site = .atatus
        configuration.batchSize = .small
        configuration.uploadFrequency = .frequent
        #if !os(watchOS)
        configuration.proxyConfiguration = [
            kCFNetworkProxiesHTTPEnable: true,
            kCFNetworkProxiesHTTPPort: 123,
            kCFNetworkProxiesHTTPProxy: "www.example.com",
            kCFProxyUsernameKey: "proxyuser",
            kCFProxyPasswordKey: "proxypass",
        ]
        #endif
        configuration.bundle = .mockWith(
            bundleIdentifier: "test",
            CFBundleShortVersionString: "1.0.0",
            CFBundleExecutable: "Test"
        )
        configuration.encryption = DataEncryptionMock()
        configuration.serverDateProvider = ServerDateProviderMock()
        configuration._internal_mutation {
            $0.additionalConfiguration = [
                CrossPlatformAttributes.atatusSource: "cp-source",
                CrossPlatformAttributes.appName: "cp-appName",
                CrossPlatformAttributes.sdkVersion: "cp-version"
            ]
        }

        XCTAssertEqual(configuration.batchSize, .small)
        XCTAssertEqual(configuration.uploadFrequency, .frequent)
        XCTAssertTrue(configuration.encryption is DataEncryptionMock)
        XCTAssertTrue(configuration.serverDateProvider is ServerDateProviderMock)

        Atatus.initialize(
            with: configuration,
            trackingConsent: .pending
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        XCTAssertTrue(core.dateProvider is SystemDateProvider)
        XCTAssertTrue(core.encryption is DataEncryptionMock)

        #if !os(watchOS)
        let urlSessionClient = try XCTUnwrap(core.httpClient as? URLSessionClient)
        let connectionProxyDictionary = try XCTUnwrap(urlSessionClient.session.configuration.connectionProxyDictionary)
        XCTAssertEqual(connectionProxyDictionary[kCFNetworkProxiesHTTPEnable] as? Bool, true)
        XCTAssertEqual(connectionProxyDictionary[kCFNetworkProxiesHTTPPort] as? Int, 123)
        XCTAssertEqual(connectionProxyDictionary[kCFNetworkProxiesHTTPProxy] as? String, "www.example.com")
        XCTAssertEqual(connectionProxyDictionary[kCFProxyUsernameKey] as? String, "proxyuser")
        XCTAssertEqual(connectionProxyDictionary[kCFProxyPasswordKey] as? String, "proxypass")
        #endif

        let context = core.contextProvider.read()
        XCTAssertEqual(context.licenseKey, "abc-123")
        XCTAssertEqual(context.env, "tests")
        XCTAssertEqual(context.site, .atatus)
        XCTAssertEqual(context.service, "service-name")
        XCTAssertEqual(context.version, "1.0.0")
        XCTAssertEqual(context.sdkVersion, "cp-version")
        XCTAssertEqual(context.applicationName, "Test")
        XCTAssertEqual(context.appName, "cp-appName")
        XCTAssertEqual(context.source, "cp-source")
        XCTAssertEqual(context.applicationBundleIdentifier, "test")
        XCTAssertEqual(context.trackingConsent, .pending)
    }

    func testGivenDefaultConfiguration_itCanBeInitialized() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )
        XCTAssertTrue(Atatus.isInitialized())
        Atatus.flushAndDeinitialize()
    }

    func testGivenInvalidConfiguration_itPrintsError() {
        let invalidConfiguration = Atatus.Configuration(licenseKey: "", env: "tests")

        Atatus.initialize(
            with: invalidConfiguration,
            trackingConsent: .mockRandom()
        )

        XCTAssertEqual(
            printFunction.printedMessage,
            "🔥 Atatus SDK usage error: `licenseKey` cannot be empty."
        )
        XCTAssertFalse(Atatus.isInitialized())
    }

    func testGivenValidConfiguration_whenInitializedMoreThanOnce_itPrintsError() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        XCTAssertEqual(
            printFunction.printedMessage,
            "🔥 Atatus SDK usage error: The 'main' instance of SDK is already initialized."
        )

        Atatus.flushAndDeinitialize()
    }

    // MARK: - Public APIs

    func testTrackingConsent() {
        let initialConsent: TrackingConsent = .mockRandom()
        let nextConsent: TrackingConsent = .mockRandom()

        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: initialConsent
        )

        let core = CoreRegistry.default as? AtatusCore
        XCTAssertEqual(core?.consentPublisher.consent, initialConsent)

        Atatus.set(trackingConsent: nextConsent)

        XCTAssertEqual(core?.consentPublisher.consent, nextConsent)

        Atatus.flushAndDeinitialize()
    }

    func testUserInfo() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        XCTAssertNil(core?.userInfoPublisher.current.id)
        XCTAssertNil(core?.userInfoPublisher.current.email)
        XCTAssertNil(core?.userInfoPublisher.current.name)
        XCTAssertEqual(core?.userInfoPublisher.current.extraInfo as? [String: Int], [:])

        Atatus.setUserInfo(
            id: "foo",
            name: "bar",
            email: "foo@bar.com",
            extraInfo: ["abc": 123]
        )
        core?.set(anonymousId: "anonymous-id")

        XCTAssertEqual(core?.userInfoPublisher.current.anonymousId, "anonymous-id")
        XCTAssertEqual(core?.userInfoPublisher.current.id, "foo")
        XCTAssertEqual(core?.userInfoPublisher.current.name, "bar")
        XCTAssertEqual(core?.userInfoPublisher.current.email, "foo@bar.com")
        XCTAssertEqual(core?.userInfoPublisher.current.extraInfo as? [String: Int], ["abc": 123])

        Atatus.clearUserInfo()

        XCTAssertEqual(core?.userInfoPublisher.current.anonymousId, "anonymous-id")
        XCTAssertNil(core?.userInfoPublisher.current.id)
        XCTAssertNil(core?.userInfoPublisher.current.email)
        XCTAssertNil(core?.userInfoPublisher.current.name)
        XCTAssertEqual(core?.userInfoPublisher.current.extraInfo as? [String: Int], [:])

        Atatus.flushAndDeinitialize()
    }

    func testAddUserProperties_mergesProperties() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        Atatus.setUserInfo(
            id: "foo",
            name: "bar",
            email: "foo@bar.com",
            extraInfo: ["abc": 123]
        )

        Atatus.addUserExtraInfo(["second": 667])

        XCTAssertEqual(core?.userInfoPublisher.current.id, "foo")
        XCTAssertEqual(core?.userInfoPublisher.current.name, "bar")
        XCTAssertEqual(core?.userInfoPublisher.current.email, "foo@bar.com")
        XCTAssertEqual(
            core?.userInfoPublisher.current.extraInfo as? [String: Int],
            ["abc": 123, "second": 667]
        )

        Atatus.flushAndDeinitialize()
    }

    func testAddUserProperties_removesProperties() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        Atatus.setUserInfo(
            id: "foo",
            name: "bar",
            email: "foo@bar.com",
            extraInfo: ["abc": 123]
        )

        Atatus.addUserExtraInfo(["abc": nil, "second": 667])

        XCTAssertEqual(core?.userInfoPublisher.current.id, "foo")
        XCTAssertEqual(core?.userInfoPublisher.current.name, "bar")
        XCTAssertEqual(core?.userInfoPublisher.current.email, "foo@bar.com")
        XCTAssertEqual(core?.userInfoPublisher.current.extraInfo as? [String: Int], ["second": 667])

        Atatus.flushAndDeinitialize()
    }

    func testAddUserProperties_overwritesProperties() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        Atatus.setUserInfo(
            id: "foo",
            name: "bar",
            email: "foo@bar.com",
            extraInfo: ["abc": 123]
        )

        Atatus.addUserExtraInfo(["abc": 444])

        XCTAssertEqual(core?.userInfoPublisher.current.id, "foo")
        XCTAssertEqual(core?.userInfoPublisher.current.name, "bar")
        XCTAssertEqual(core?.userInfoPublisher.current.email, "foo@bar.com")
        XCTAssertEqual(core?.userInfoPublisher.current.extraInfo as? [String: Int], ["abc": 444])

        Atatus.flushAndDeinitialize()
    }

    func testAccountInfo() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        XCTAssertNil(core?.accountInfoPublisher.current)

        Atatus.setAccountInfo(
            id: "foo",
            name: "bar",
            extraInfo: ["abc": 123]
        )

        XCTAssertEqual(core?.accountInfoPublisher.current?.id, "foo")
        XCTAssertEqual(core?.accountInfoPublisher.current?.name, "bar")
        XCTAssertEqual(core?.accountInfoPublisher.current?.extraInfo as? [String: Int], ["abc": 123])

        Atatus.flushAndDeinitialize()
    }

    func testAddAccountProperties_mergesProperties() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        Atatus.setAccountInfo(
            id: "foo",
            name: "bar",
            extraInfo: ["abc": 123]
        )

        Atatus.addAccountExtraInfo(["second": 667])

        XCTAssertEqual(core?.accountInfoPublisher.current?.id, "foo")
        XCTAssertEqual(core?.accountInfoPublisher.current?.name, "bar")
        XCTAssertEqual(
            core?.accountInfoPublisher.current?.extraInfo as? [String: Int],
            ["abc": 123, "second": 667]
        )

        Atatus.flushAndDeinitialize()
    }

    func testAddAccountProperties_removesProperties() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        Atatus.setAccountInfo(
            id: "foo",
            name: "bar",
            extraInfo: ["abc": 123]
        )

        Atatus.addAccountExtraInfo(["abc": nil, "second": 667])

        XCTAssertEqual(core?.accountInfoPublisher.current?.id, "foo")
        XCTAssertEqual(core?.accountInfoPublisher.current?.name, "bar")
        XCTAssertEqual(core?.accountInfoPublisher.current?.extraInfo as? [String: Int], ["second": 667])

        Atatus.flushAndDeinitialize()
    }

    func testAddAccountProperties_overwritesProperties() {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        let core = CoreRegistry.default as? AtatusCore

        Atatus.setAccountInfo(
            id: "foo",
            name: "bar",
            extraInfo: ["abc": 123]
        )

        Atatus.addAccountExtraInfo(["abc": 444])

        XCTAssertEqual(core?.accountInfoPublisher.current?.id, "foo")
        XCTAssertEqual(core?.accountInfoPublisher.current?.name, "bar")
        XCTAssertEqual(core?.accountInfoPublisher.current?.extraInfo as? [String: Int], ["abc": 444])

        Atatus.flushAndDeinitialize()
    }

    func testDefaultVerbosityLevel() {
        XCTAssertNil(Atatus.verbosityLevel)
    }

    func testGivenDataStoredInAllFeatureDirectories_whenClearAllDataIsUsed_allFilesAreRemoved() throws {
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        Logs.enable()
        Trace.enable()

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)

        // On SDK init, underlying `ConsentAwareDataWriter` performs data migration for each feature, which includes
        // data removal in `unauthorised` (`.pending`) directory. To not cause test flakiness, we must ensure that
        // mock data is written only after this operation completes - otherwise, migration may delete mocked files.
        core.readWriteQueue.sync {}

        // Given
        let featureDirectories: [FeatureDirectories] = [
            try core.directory.getFeatureDirectories(forFeatureNamed: "logging"),
            try core.directory.getFeatureDirectories(forFeatureNamed: "tracing"),
        ]

        let scope = core.scope(for: TraceFeature.self)
        scope.dataStore.setValue("foo".data(using: .utf8)!, forKey: "bar")

        // Wait for async clear completion in all features:
        core.readWriteQueue.sync {}
        let tracingDataStoreDir = try core.directory.coreDirectory.subdirectory(path: core.directory.getDataStorePath(forFeatureNamed: "tracing"))
        XCTAssertTrue(tracingDataStoreDir.hasFile(named: "bar"))

        var allDirectories: [Directory] = featureDirectories.flatMap { [$0.authorized, $0.unauthorized] }
        allDirectories.append(.init(url: tracingDataStoreDir.url))
        try allDirectories.forEach { directory in _ = try directory.createFile(named: .mockRandom()) }

        // When
        Atatus.clearAllData()

        // Wait for async clear completion in all features:
        core.readWriteQueue.sync {}

        // Then
        let files: [File] = allDirectories.reduce([], { acc, nextDirectory in
            let next = try? nextDirectory.files()
            return acc + (next ?? [])
        })
        XCTAssertEqual(files, [], "All files must be removed")

        Atatus.flushAndDeinitialize()
    }

    func testServerDateProvider() throws {
        // Given
        var config = defaultConfig
        let serverDateProvider = ServerDateProviderMock()
        config.serverDateProvider = serverDateProvider

        // When
        Atatus.initialize(
            with: config,
            trackingConsent: .mockRandom()
        )

        serverDateProvider.offset = -1

        // Then
        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.serverTimeOffset, -1)

        Atatus.flushAndDeinitialize()
    }

    func testRemoveV1DeprecatedFolders() throws {
        // Given
        let cache = try Directory.cache()
        let directories = ["com.atatus.logs", "com.atatus.traces", "com.atatus.rum"]
        try directories.forEach {
            _ = try cache.createSubdirectory(path: $0).createFile(named: "test")
        }

        // When
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )

        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        // Wait for async deletion
        core.readWriteQueue.sync {}

        // Then
        XCTAssertThrowsError(try cache.subdirectory(path: "com.atatus.logs"))
        XCTAssertThrowsError(try cache.subdirectory(path: "com.atatus.traces"))
        XCTAssertThrowsError(try cache.subdirectory(path: "com.atatus.rum"))
    }

    func testCustomSDKInstance() throws {
        // When
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom(),
            instanceName: "test"
        )

        defer { Atatus.flushAndDeinitialize(instanceName: "test") }

        // Then
        XCTAssertTrue(CoreRegistry.default is NOPAtatusCore)
        XCTAssertTrue(CoreRegistry.instance(named: "test") is AtatusCore)
    }

    func testStopSDKInstance() throws {
        // Given
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom(),
            instanceName: "test"
        )

        // Then
        XCTAssertTrue(CoreRegistry.instance(named: "test") is AtatusCore)

        // When
        Atatus.stopInstance(named: "test")

        // Then
        XCTAssertTrue(CoreRegistry.instance(named: "test") is NOPAtatusCore)
    }

    func testGivenDefaultSDKInstanceInitialized_customOneCanBeInitializedAfterIt() throws {
        let defaultConfig = Atatus.Configuration(licenseKey: "abc-123", env: "default")
        let customConfig = Atatus.Configuration(licenseKey: "def-456", env: "custom")

        // Given
        Atatus.initialize(
            with: defaultConfig,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        // When
        Atatus.initialize(
            with: customConfig,
            trackingConsent: .mockRandom(),
            instanceName: "custom-instance"
        )
        defer { Atatus.flushAndDeinitialize(instanceName: "custom-instance") }

        // Then
        XCTAssertTrue(CoreRegistry.default is AtatusCore)
        XCTAssertTrue(CoreRegistry.instance(named: "custom-instance") is AtatusCore)
    }
}
