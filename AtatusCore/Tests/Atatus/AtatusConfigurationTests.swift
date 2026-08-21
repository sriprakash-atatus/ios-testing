/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed `dd*` types to `Atatus*`; renamed `clientToken` to `licenseKey`; renamed
// the build `variant` to `appName`; renamed the `ddsource` / `ddtags` query parameters to `atatus_source` /
// `atatustags`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence
// header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusCore

class AtatusConfigurationTests: XCTestCase {
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
        XCTAssertEqual(context.site, .atatus) // ATCHG: default site is the Atatus intake
        XCTAssertEqual(context.service, "test")
        XCTAssertEqual(context.version, "1.0.0")
        XCTAssertEqual(context.sdkVersion, __sdkVersion)
        XCTAssertEqual(context.applicationName, "Test")
        XCTAssertNil(context.appName)
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
        configuration.batchProcessingLevel = .high
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
        XCTAssertEqual(configuration.batchProcessingLevel, .high)
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

    func testGivenNoExecutable_itUsesBundleTypeAsApplicationName() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            CFBundleExecutable: nil
        )

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.applicationName, "iOSApp")
    }

    func testGivenNoExecutable_andWidgetExecutable_itUsesBundleTypeAsApplicationName() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            bundlePath: "widget.appex",
            CFBundleExecutable: nil
        )

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.applicationName, "iOSAppExtension")
    }

    func testGivenNoBundleVersion_itUsesShortVersionString() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            CFBundleVersion: nil,
            CFBundleShortVersionString: "1.2.3"
        )

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.version, "1.2.3")
    }

    func testGivenNoBundleShortVersion_itUsesDefaultValue() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            CFBundleVersion: nil,
            CFBundleShortVersionString: nil
        )

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.version, "0.0.0")
        XCTAssertEqual(context.buildNumber, "0")
    }

    func testGivenNoBundleVersion_itUsesDefaultValue() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            CFBundleVersion: "FFFFF",
            CFBundleShortVersionString: nil
        )

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.buildNumber, "FFFFF")
    }

    func testGivenNoBundleIdentifier_itUsesDefaultValues() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            bundleIdentifier: nil
        )

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.applicationBundleIdentifier, "unknown")
        XCTAssertEqual(context.service, "ios")
    }

    func testGivenNoBundleIdentifier_itUsesUnknown() throws {
        var configuration = defaultConfig

        configuration.bundle = .mockWith(
            bundleIdentifier: nil
        )

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.applicationBundleIdentifier, "unknown")
    }

    func testiOSAppBundleType() throws {
        var configuration = defaultConfig
        configuration.bundle = .mockWith(bundlePath: "bundle.path.app")

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.applicationBundleType, .iOSApp)
    }

    func testiOSAppExtensionBundleType() throws {
        var configuration = defaultConfig
        configuration.bundle = .mockWith(bundlePath: "bundle.path.appex")

        Atatus.initialize(
            with: configuration,
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()
        XCTAssertEqual(context.applicationBundleType, .iOSAppExtension)
    }

    func testEnvironment() throws {
        func verify(validEnv env: String) throws {
            Atatus.initialize(
                with: Atatus.Configuration(licenseKey: "abc-123", env: env),
                trackingConsent: .mockRandom()
            )
            defer { Atatus.flushAndDeinitialize() }
            XCTAssertNil(printFunction.printedMessage)
        }

        func verify(invalidEnv env: String) {
            Atatus.initialize(
                with: Atatus.Configuration(licenseKey: "abc-123", env: env),
                trackingConsent: .mockRandom()
            )
            XCTAssertEqual(
                printFunction.printedMessage,
                "🔥 Atatus SDK usage error: `env`: \(env) contains illegal characters (only alphanumerics and `_` are allowed)"
            )
        }

        try verify(validEnv: "staging_1")
        try verify(validEnv: "production")
        try verify(validEnv: "production:some")
        try verify(validEnv: "pro/d-uct.ion_")

        verify(invalidEnv: "")
        verify(invalidEnv: "*^@!&#")
        verify(invalidEnv: "abc def")
        verify(invalidEnv: "*^@!&#")
        verify(invalidEnv: "*^@!&#\nsome_env")
        verify(invalidEnv: String(repeating: "a", count: 197))
    }

    func testApplicationVersionOverride() throws {
        var configuration = defaultConfig
        configuration.additionalConfiguration[CrossPlatformAttributes.version] = "5.23.2"

        Atatus.initialize(with: configuration, trackingConsent: .mockRandom())
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()

        XCTAssertEqual(context.version, "5.23.2")
    }

    func testPublicVersionProperty() throws {
        var configuration = defaultConfig
        configuration.version = "my-completely-custom-version"
        configuration.bundle = .mockWith(
            CFBundleShortVersionString: "1.0.0"
        )

        Atatus.initialize(with: configuration, trackingConsent: .mockRandom())
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()

        XCTAssertEqual(context.version, "my-completely-custom-version")
    }

    func testPublicVersionPropertyWithNilUsesBundle() throws {
        var configuration = defaultConfig
        configuration.version = nil
        configuration.bundle = .mockWith(
            CFBundleShortVersionString: "1.5.0"
        )

        Atatus.initialize(with: configuration, trackingConsent: .mockRandom())
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()

        XCTAssertEqual(context.version, "1.5.0")
    }

    func testCrossPlatformVersionOverridesTakePrecedenceOverPublicVersion() throws {
        var configuration = defaultConfig
        configuration.version = "2.0.0-native"
        configuration.bundle = .mockWith(
            CFBundleShortVersionString: "1.0.0"
        )
        configuration.additionalConfiguration[CrossPlatformAttributes.version] = "3.0.0-crossplatform"

        Atatus.initialize(with: configuration, trackingConsent: .mockRandom())
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()

        // Cross-platform override should take precedence
        XCTAssertEqual(context.version, "3.0.0-crossplatform")
    }

    func testGivenBuildId_itSetsContext() throws {
        // Given
        let buildId: String = .mockRandom(length: 32)
        var configuration = defaultConfig
        configuration.additionalConfiguration[CrossPlatformAttributes.buildId] = buildId

        // When
        Atatus.initialize(with: configuration, trackingConsent: .mockRandom())
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()

        // Then
        XCTAssertEqual(context.buildId, buildId)
    }

    func testGivenNativeSourceType_itSetsInContext() throws {
        // Given
        let nativeSourceType: String = .mockRandom()
        var configuration = defaultConfig
        configuration.additionalConfiguration[CrossPlatformAttributes.nativeSourceType] = nativeSourceType

        // When
        Atatus.initialize(with: configuration, trackingConsent: .mockRandom())
        defer { Atatus.flushAndDeinitialize() }

        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        let context = core.contextProvider.read()

        // Then
        XCTAssertEqual(context.nativeSourceOverride, nativeSourceType)
    }
}
