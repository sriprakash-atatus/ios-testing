/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`, `ddLogs` -> `AtatusLogs`; renamed `dd*` members to `at*`; renamed `clientToken` to
// `licenseKey`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence
// header.

import XCTest
import TestUtilities
@testable import AtatusCore
import AtatusInternal
import AtatusLogs

class Atatus_MultipleInstancesIntegrationTests: XCTestCase {
    /// The configuraiton of default instance of SDK.
    private var defaultInstanceConfig = Atatus.Configuration(licenseKey: "main-token", env: "default-env")
    /// The configuraiton of custom instance of SDK.
    private var customInstanceConfig = Atatus.Configuration(licenseKey: "custom-token", env: "custom-env")

    override func setUp() {
        super.setUp()
        CreateTemporaryDirectory()

        // Root system directory for both instances:
        let systemDirectory = Directory(url: temporaryDirectory)
        defaultInstanceConfig.systemDirectory = { systemDirectory }
        customInstanceConfig.systemDirectory = { systemDirectory }
    }

    override func tearDown() {
        DeleteTemporaryDirectory()
        super.tearDown()
    }

    func testGivenTwoInstancesOfSDK_whenCollectingLogs_thenEachSDKUploadsItsOwnData() throws {
        let customInstanceName = "custom"
        let numberOfLogs = 10
        let defaultHTTPClient = HTTPClientMock(responseCode: 200)
        let customHTTPClient = HTTPClientMock(responseCode: 200)
        defaultInstanceConfig.httpClientFactory = { _ in defaultHTTPClient }
        customInstanceConfig.httpClientFactory = { _ in customHTTPClient }
        defaultInstanceConfig.bundle = .mockWith(bundleIdentifier: "com.bundle.default", CFBundleShortVersionString: "1.0-default")
        customInstanceConfig.bundle = .mockWith(bundleIdentifier: "com.bundle.custom", CFBundleShortVersionString: "1.0-custom")

        // Given
        Atatus.initialize(with: defaultInstanceConfig, trackingConsent: .granted)
        Atatus.initialize(with: customInstanceConfig, trackingConsent: .granted, instanceName: customInstanceName)

        Logs.enable(with: .init())
        Logs.enable(with: .init(), in: Atatus.sdkInstance(named: customInstanceName))

        let defaultLogger = Logger.create()
        let customLogger = Logger.create(in: Atatus.sdkInstance(named: customInstanceName))

        // When
        for _ in 0..<numberOfLogs {
            defaultLogger.info("Default SDK log")
            customLogger.info("Custom SDK log")
        }

        // Then
        Atatus.flushAndDeinitialize()
        Atatus.flushAndDeinitialize(instanceName: customInstanceName)

        let defaultInstanceRequests = defaultHTTPClient.requestsSent()
        let customInstanceRequests = customHTTPClient.requestsSent()
        XCTAssertGreaterThan(defaultInstanceRequests.count, 0, "Default instance should send some data")
        XCTAssertGreaterThan(customInstanceRequests.count, 0, "Custom instance should send some data")

        defaultInstanceRequests.forEach { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: URLRequestBuilder.HTTPHeader.atAPIKeyHeaderField),
                defaultInstanceConfig.licenseKey,
                "Default instance should authenticate data using '\(defaultInstanceConfig.licenseKey)' client token"
            )
        }
        customInstanceRequests.forEach { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: URLRequestBuilder.HTTPHeader.atAPIKeyHeaderField),
                customInstanceConfig.licenseKey,
                "Custom instance should authenticate data using '\(customInstanceConfig.licenseKey)' client token"
            )
        }

        let defaultLogs = try defaultInstanceRequests.flatMap { try LogMatcher.fromLogsRequest($0) }
        let customLogs = try customInstanceRequests.flatMap { try LogMatcher.fromLogsRequest($0) }

        XCTAssertEqual(defaultLogs.count, numberOfLogs, "Default instance should send \(numberOfLogs) logs")
        XCTAssertEqual(customLogs.count, numberOfLogs, "Custom instance should send \(numberOfLogs) logs")
        defaultLogs.forEach { log in
            log.assertService(equals: "com.bundle.default")
            log.assertMessage(equals: "Default SDK log")
            log.assertTags(equal: [
                "env:default-env",
                "version:1.0-default",
                "sdk_version:\(__sdkVersion)",
                "service:com.bundle.default"
            ])
        }
        customLogs.forEach { log in
            log.assertService(equals: "com.bundle.custom")
            log.assertMessage(equals: "Custom SDK log")
            log.assertTags(equal: [
                "env:custom-env",
                "version:1.0-custom",
                "sdk_version:\(__sdkVersion)",
                "service:com.bundle.custom"
            ])
        }
    }
}
