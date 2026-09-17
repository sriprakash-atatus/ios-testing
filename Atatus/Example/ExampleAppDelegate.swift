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
import AtatusSessionReplay
import OpenTelemetryApi

let serviceName = "ios-sdk-example-app"

var logger: LoggerProtocol!
var tracer: OTTracer { Tracer.shared() }
var rumMonitor: RUMMonitorProtocol { RUMMonitor.shared() }
var otelTracer: OpenTelemetryApi.Tracer {
    OpenTelemetry
        .instance
        .tracerProvider
        .get(instrumentationName: "", instrumentationVersion: nil)
}

final class DummySessionDataDelegate: NSObject, URLSessionDataDelegate {}

@main
class ExampleAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if Environment.isRunningUnitTests() {
            return false
        }

        // Initialize Atatus SDK
        Atatus.initialize(
            with: Atatus.Configuration(
                licenseKey: "lic_apm_3c890780dd3a4acd97fab9ce6eb5b917",
                env: "demo",
                serverUrl: "https://demo.atatus.com",
                service: serviceName,
                batchSize: .small,
                uploadFrequency: .frequent
            ),
            trackingConsent: .granted
        )

        // Set user information
        Atatus.setUserInfo(id: "abcd-1234",
        name: "foo", 
        email: "foo@example.com", 
        extraInfo: ["key-extraUserInfo": "value-extraUserInfo"])

        // Set account information
        Atatus.setAccountInfo(id: "account-1234", name: "account-US")

        // Enable Logs
        Logs.enable(
            with: Logs.Configuration(
                customEndpoint: Environment.readCustomLogsURL()
            )
        )

        // Enable Crash Reporting
        CrashReporting.enable()

        // Set highest verbosity level to see debugging logs from the SDK
        Atatus.verbosityLevel = .debug

        // Enable Trace
        Trace.enable(
            with: Trace.Configuration(
                tags: ["testing-tag": "my-value"],
                urlSessionTracking: .init(
                    firstPartyHostsTracing: .traceWithHeaders(
                        hostsWithHeaders: [
                            "api.shopist.io": [.atatus],
                            "demo.atatus.com": [.atatus, .tracecontext],
                            "10.40.31.91": [.atatus, .tracecontext],
                            "localhost": [.atatus, .tracecontext],
                            "127.0.0.1": [.atatus, .tracecontext]
                        ],
                        sampleRate: 100
                    )
                ),
                networkInfoEnabled: true,
                customEndpoint: Environment.readCustomTraceURL()
            )
        )

        // Enable RUM
        RUM.enable(
            with: RUM.Configuration(
                urlSessionTracking: .init(
                    firstPartyHostsTracing: .traceWithHeaders(
                        hostsWithHeaders: [
                            "api.shopist.io": [.atatus],
                            "demo.atatus.com": [.atatus, .tracecontext],
                            "10.40.31.91": [.atatus, .tracecontext],
                            "localhost": [.atatus, .tracecontext],
                            "127.0.0.1": [.atatus, .tracecontext]
                        ],
                        sampleRate: 100
                    ),
                    resourceAttributesProvider: { req, resp, data, err in
                        print("⭐️ [Attributes Provider] data: \(String(describing: data))")
                        return [:]
                    }
                ),
                trackBackgroundEvents: true,
                trackWatchdogTerminations: true,
                customEndpoint: Environment.readCustomRUMURL(),
                telemetrySampleRate: 100
            )
        )
        RUMMonitor.shared().debug = true

        // Enable Session Replay
        SessionReplay.enable(
            with: SessionReplay.Configuration(
                replaySampleRate: 100,
                textAndInputPrivacyLevel: .maskSensitiveInputs,
                imagePrivacyLevel: .maskNone,
                touchPrivacyLevel: .show
            )
        )

        URLSessionInstrumentation.enableDurationBreakdown(with: .init(delegateClass: DummySessionDataDelegate.self))

        // Register Trace Provider
        OpenTelemetry.registerTracerProvider(
            tracerProvider: OTelTracerProvider()
        )
        Logs.addAttribute(forKey: "testing-attribute", value: "my-value")

        // Create Logger
        logger = Logger.create(
            with: Logger.Configuration(
                name: "logger-name",
                networkInfoEnabled: true,
                consoleLogFormat: .shortWith(prefix: "[iOS App] ")
            )
        )

        logger.addAttribute(forKey: "device-model", value: UIDevice.current.model)

        #if DEBUG
        logger.addTag(withKey: "build_configuration", value: "debug")
        #else
        logger.addTag(withKey: "build_configuration", value: "release")
        #endif

        // Launch initial screen depending on the launch configuration
        #if os(visionOS)
        let storyboard = UIStoryboard(name: "Main iOS", bundle: nil)
        launch(storyboard: storyboard)
        #endif

        #if os(iOS)
        // Instantiate location monitor if the Example app is run in interactive mode. This will
        // enable background location tracking if it was started in previous session.
        // Note: Background location monitoring is iOS-only (not available on tvOS or visionOS).
        if Environment.isRunningInteractive() {
            backgroundLocationMonitor = BackgroundLocationMonitor(rum: rumMonitor)
        }
        #endif

        return true
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if Environment.isRunningInteractive() {
            installConsoleOutputInterceptor()
        }
        return true
    }

    #if os(iOS)
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    #endif

    func launch(storyboard: UIStoryboard) {
        if window == nil {
            #if os(visionOS)
            window = UIWindow()
            #else
            window = UIWindow(frame: UIScreen.main.bounds)
            #endif
            window?.makeKeyAndVisible()
        }
        window?.rootViewController = storyboard.instantiateInitialViewController()!
    }
}

#if os(iOS)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main iOS", bundle: nil)
        window.rootViewController = storyboard.instantiateInitialViewController()
        self.window = window
        (UIApplication.shared.delegate as? ExampleAppDelegate)?.window = window
        window.makeKeyAndVisible()
    }
}
#endif
