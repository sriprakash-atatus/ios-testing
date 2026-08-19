/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddCrashReporting` -> `AtatusCrashReporting`, `ddLogs` -> `AtatusLogs`, `ddRUM` ->
// `AtatusRUM`, `ddTrace` -> `AtatusTrace`; renamed `clientToken` to `licenseKey`; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import UIKit
import AtatusCore
import AtatusLogs
import AtatusTrace
import AtatusRUM
import AtatusCrashReporting
@_spi(Internal) import AtatusInternal

var logger: LoggerProtocol?
var rumMonitor: RUMMonitorProtocol { RUMMonitor.shared() }

protocol AppConfiguration {
    /// The tracking consent value applied when initializing the SDK.
    var initialTrackingConsent: TrackingConsent { get }

    /// Atatus SDK configuration for given app configuration.
    func sdkConfiguration() -> Atatus.Configuration

    /// Returns the initial Storyboard to launch the app in this configuration.
    func initialStoryboard() -> UIStoryboard?

    /// `TestScenario` passed in ENV parameters or `nil` if the app was launched directly.
    var testScenario: TestScenario? { get }
}

/// The configuration used when launching the Example app for Atatus SDK integration tests (⌘+U).
struct UITestsAppConfiguration: AppConfiguration {
    let testScenario: TestScenario? = Environment.testScenarioClassName()
        .flatMap { className in initializeTestScenario(with: className) }

    init() {
        if Environment.shouldClearPersistentData() {
            PersistenceHelpers.deleteAllSDKData()
        }

        // Handle messages received from UITest runner:
        try! MessagePortChannel.createReceiver().startListening { message in
            switch message {
            case .endRUMSession: markRUMSessionAsEnded()
            }
        }
    }

    var initialTrackingConsent: TrackingConsent {
        return testScenario!.initialTrackingConsent
    }

    func sdkConfiguration() -> Atatus.Configuration {
        // ATCHG: Read from the environment, falling back to the UI-test placeholders the
        // integration assertions expect, so the same app can also report to a real intake.
        var configuration = Atatus.Configuration(
            licenseKey: Environment.licenseKey(),
            env: Environment.env(),
            service: Environment.service(),
            batchSize: .small,
            uploadFrequency: .frequent
        )

        // Apply the scenario configuration
        testScenario?.override(configuration: &configuration)

        return configuration
    }

    func initialStoryboard() -> UIStoryboard? {
        guard let testScenario = testScenario else {
            return nil
        }
        return UIStoryboard(name: type(of: testScenario).storyboardName, bundle: nil)
    }
}

extension AppConfiguration {
    func initializeSDK() {
        // Initialize Atatus SDK
        Atatus.initialize(
            with: appConfiguration.sdkConfiguration(),
            trackingConsent: appConfiguration.initialTrackingConsent
        )

        appConfiguration.testScenario?.configureFeatures()

        // ATCHG: `LogsHeartbeatScheduler.isLogsAllowed` defaults to `false`, so the Logs feature
        // holds every batch back until the logs heartbeat answers `allowAgent: true`. That
        // heartbeat talks to the real Atatus backend, which the UI tests deliberately never reach:
        // they point each product at the local mock intake using a placeholder license key, so the
        // heartbeat always answers `false` and no log is ever uploaded.
        //
        // Open the gate only when logs are mocked. When the app reports to a real intake the real
        // heartbeat still decides, so this does not mask the production behaviour.
        //
        // The scheduler is also stopped: `Atatus.initialize()` starts the heartbeat timer with
        // `deadline: .now()`, so its async response can arrive after `setLogsAllowed(true)` and
        // overwrite it back to `false`. Stopping the scheduler cancels that in-flight request.
        if Environment.serverMockConfiguration()?.logsEndpoint != nil {
            LogsHeartbeatScheduler.shared.stop()
            LogsHeartbeatScheduler.setLogsAllowed(true)
        }

        // Set user information
        Atatus.setUserInfo(id: "abcd-1234", name: "foo", email: "foo@example.com", extraInfo: ["key-extraUserInfo": "value-extraUserInfo"])

        // Create Logger
        logger = Logger.create(
            with: Logger.Configuration(
                name: "logger-name",
                networkInfoEnabled: true,
                consoleLogFormat: .shortWith(prefix: "[iOS App] ")
            )
        )

        logger?.addAttribute(forKey: "device-model", value: UIDevice.current.model)

        #if DEBUG
        logger?.addTag(withKey: "build_configuration", value: "debug")
        #else
        logger?.addTag(withKey: "build_configuration", value: "release")
        #endif

        // Set highest verbosity level to see debugging logs from the SDK
        Atatus.verbosityLevel = .debug

        // Enable RUM Views debugging
        RUMMonitor.shared().debug = true
    }

    func deinitializeSDK() {
        Atatus.stopInstance()
        logger = nil
    }
}
