/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; renamed `clientToken` to `licenseKey`; rebranded the `dd` name to `Atatus` in comments and
// docs; rebranded the licence header.

import Foundation

/// Encapsulates Python server configuration passed through ENV variable from UITest runner to the app process.
internal struct HTTPServerMockConfiguration: Codable {
    /// Python server URL to record Logging requests.
    var logsEndpoint: URL? = nil
    /// Python server URL to record Tracing requests.
    var tracesEndpoint: URL? = nil
    /// Python server URL to record RUM requests.
    var rumEndpoint: URL? = nil
    /// Python server URL to record Session Replay requests.
    var srEndpoint: URL? = nil

    /// Python server URLs to record custom requests, e.g. custom data requests
    /// to assert trace headers propagation.
    var instrumentedEndpoints: [URL] = []

    // MARK: - Coding

    /// Encodes this struct to base-64 encoded string so it can be passed in ENV variable.
    var toEnvironmentValue: String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return data.base64EncodedString()
    }

    /// Decodes this struct from base-64 encoded string so it can be read from ENV variable.
    fileprivate static func from(environmentValue: String) -> HTTPServerMockConfiguration {
        let decoder = JSONDecoder()
        let data = Data(base64Encoded: environmentValue)!
        return try! decoder.decode(HTTPServerMockConfiguration.self, from: data)
    }
}

/// Defines the way of instrumenting `URLSession` for RUM and Tracing scenarios.
internal struct URLSessionSetup: Codable {
    /// The method of instrumenting `URLSession` with `ATURLSessionDelegate` and providing `firstPartyHosts`
    /// information to RUM and Tracing.
    enum InstrumentationMethod: CaseIterable, Codable {
        /// Use a custom delegate.
        /// and define `firstPartyHosts` in feature configuration.
        case delegateUsingFeatureFirstPartyHosts
        /// Use a custom delegate.
        /// and define `firstPartyHosts` with delegate's configuration.
        case delegateWithAdditionalFirstPartyHosts
    }

    /// A method of instrumenting `URLSession` with `ATURLSessionDelegate`.
    let instrumentationMethod: InstrumentationMethod

    /// The moment of initializing `URLSession` (and `ATURLSessionDelegate`) in relation to starting SDK.
    enum InitializationMethod: CaseIterable, Codable {
        /// Initialize `URLSession` (and delegate) before starting SDK.
        case beforeSDK
        /// Initialize `URLSession` (and delegate) after starting SDK.
        case afterSDK
    }

    /// A method of initializing `URLSession` (and `ATURLSessionDelegate`).
    let initializationMethod: InitializationMethod

    // MARK: - Coding

    /// Encodes this struct to base-64 encoded string so it can be passed in ENV variable.
    var toEnvironmentValue: String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return data.base64EncodedString()
    }

    /// Decodes this struct from base-64 encoded string so it can be read from ENV variable.
    fileprivate static func from(environmentValue: String) -> URLSessionSetup {
        let decoder = JSONDecoder()
        let data = Data(base64Encoded: environmentValue)!
        return try! decoder.decode(URLSessionSetup.self, from: data)
    }
}

internal struct Environment {
    /// ENV variables shared between UITests and Example targets.
    struct Variable {
        static let testScenarioClassName = "AT_TEST_SCENARIO_CLASS_NAME"
        static let serverMockConfiguration = "AT_TEST_SERVER_MOCK_CONFIGURATION"
        static let urlSessionSetup = "AT_TEST_URL_SESSION_SETUP"

        // ATCHG: Credentials read from the environment so a CI job can point this app at a real
        // Atatus intake without any key being committed. Unset in the UI tests, which assert the
        // placeholders in `Constants` on the recorded intake requests.
        static let licenseKey = "AT_TEST_LICENSE_KEY"
        static let rumApplicationID = "AT_TEST_RUM_APPLICATION_ID"
        static let service = "AT_TEST_SERVICE"
        static let env = "AT_TEST_ENV"
        /// A first party URL the app requests once, to exercise network tracing and trace
        /// propagation against a real backend. Skipped when unset.
        static let tracedRequestURL = "AT_TEST_TRACED_REQUEST_URL"
        /// Base URL of the backend the e-commerce scenario's store talks to. Its requests are what
        /// RUM and Trace auto-instrumentation capture, so pointing this elsewhere is how a run keeps
        /// its traffic inside its own network.
        static let storeAPIURL = "AT_TEST_STORE_API_URL"
    }
    /// Launch arguments shared between UITests and Example targets.
    struct Argument {
        static let isRunningUnitTests       = "IS_RUNNING_UNIT_TESTS"
        static let isRunningUITests         = "IS_RUNNING_UI_TESTS"
        static let doNotClearPersistentData = "DO_NOT_CLEAR_PERSISTENT_DATA"
    }
    /// Common constants shared between UITests and Example targets.
    struct Constants {
        /// The name of the view indicating the end of RUM session in RUM-related `TestScenarios`.
        static let rumSessionEndViewName = "RUMSessionEndView"

        // ATCHG: Defaults used when the matching `Variable` is not set. The UI tests assert these
        // exact values, so they must not change.
        static let defaultLicenseKey = "ui-tests-client-token"
        static let defaultRUMApplicationID = "rum-application-id"
        static let defaultService = "ui-tests-service-name"
        static let defaultEnv = "integration"
        /// A public catalogue API, so the e-commerce scenario makes the requests a shop actually
        /// makes. Overridden with `AT_TEST_STORE_API_URL`.
        static let defaultStoreAPIURL = URL(string: "https://fakestoreapi.com")!
    }
    struct InfoPlistKey {
        static let licenseKey      = "AtatusClientToken"
        static let rumApplicationID = "RUMApplicationID"

        static let customLogsURL    = "CustomLogsURL"
        static let customTraceURL   = "CustomTraceURL"
        static let customRUMURL     = "CustomRUMURL"
    }

    // MARK: - Launch Arguments

    static func isRunningUnitTests() -> Bool {
        return ProcessInfo.processInfo.arguments.contains(Argument.isRunningUnitTests)
    }

    static func isRunningUITests() -> Bool {
        return ProcessInfo.processInfo.arguments.contains(Argument.isRunningUITests)
    }

    /// If running `Example` in interactive, debug mode (launching it with 'Run' in Xcode or by tapping on the app icon).
    static func isRunningInteractive() -> Bool {
        return !isRunningUITests() && !isRunningUnitTests()
    }

    static func shouldClearPersistentData() -> Bool {
        return !ProcessInfo.processInfo.arguments.contains(Argument.doNotClearPersistentData)
    }

    // MARK: - Launch Variables

    static func testScenarioClassName() -> String? {
        return ProcessInfo.processInfo.environment[Variable.testScenarioClassName]
    }

    static func serverMockConfiguration() -> HTTPServerMockConfiguration? {
        if let environmentValue = ProcessInfo.processInfo.environment[Variable.serverMockConfiguration] {
            return HTTPServerMockConfiguration.from(environmentValue: environmentValue)
        }
        return nil
    }

    static func urlSessionSetup() -> URLSessionSetup? {
        if let environmentValue = ProcessInfo.processInfo.environment[Variable.urlSessionSetup] {
            return URLSessionSetup.from(environmentValue: environmentValue)
        }
        return nil
    }

    // ATCHG: Credentials, environment-overridable.

    /// The license key the SDK is initialized with.
    static func licenseKey() -> String {
        nonEmptyValue(of: Variable.licenseKey) ?? Constants.defaultLicenseKey
    }

    /// The RUM application ID that RUM-enabling scenarios use.
    static func rumApplicationID() -> String {
        nonEmptyValue(of: Variable.rumApplicationID) ?? Constants.defaultRUMApplicationID
    }

    /// The `service` reported to the intake.
    static func service() -> String {
        nonEmptyValue(of: Variable.service) ?? Constants.defaultService
    }

    /// The `env` reported to the intake.
    static func env() -> String {
        nonEmptyValue(of: Variable.env) ?? Constants.defaultEnv
    }

    /// A first party URL to request once, or `nil` to skip the traced request.
    static func tracedRequestURL() -> URL? {
        nonEmptyValue(of: Variable.tracedRequestURL).flatMap { URL(string: $0) }
    }

    /// The backend the e-commerce scenario's store calls.
    static func storeAPIURL() -> URL {
        nonEmptyValue(of: Variable.storeAPIURL).flatMap { URL(string: $0) } ?? Constants.defaultStoreAPIURL
    }

    /// Reads an ENV variable, treating a blank value the same as an absent one — CI runners
    /// routinely export unset secrets as empty strings.
    private static func nonEmptyValue(of variable: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[variable] else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    // ATCHG: End

    // MARK: - Info.plist

    static func readClientToken() -> String {
        guard let licenseKey = Bundle.main.infoDictionary?[InfoPlistKey.licenseKey] as? String, !licenseKey.isEmpty else {
            fatalError("""
            ✋⛔️ Cannot read `\(InfoPlistKey.licenseKey)` from `Info.plist` dictionary.
            Please update `Atatus.xcconfig` in the repository root with your own
            client token obtained on atatus.com.
            You might need to run `Product > Clean Build Folder` before retrying.
            """)
        }
        return licenseKey
    }

    static func readRUMApplicationID() -> String {
        guard let rumApplicationID = Bundle.main.infoDictionary![InfoPlistKey.rumApplicationID] as? String, !rumApplicationID.isEmpty else {
            fatalError("""
            ✋⛔️ Cannot read `\(InfoPlistKey.rumApplicationID)` from `Info.plist` dictionary.
            Please update `Atatus.xcconfig` in the repository root with your own
            RUM application id obtained on atatus.com.
            You might need to run `Product > Clean Build Folder` before retrying.
            """)
        }
        return rumApplicationID
    }

    static func readCustomLogsURL() -> URL? {
        if let customLogsURL = Bundle.main.infoDictionary![InfoPlistKey.customLogsURL] as? String,
           !customLogsURL.isEmpty {
            return URL(string: "https://\(customLogsURL)")
        }
        return nil
    }

    static func readCustomTraceURL() -> URL? {
        if let customTraceURL = Bundle.main.infoDictionary![InfoPlistKey.customTraceURL] as? String,
           !customTraceURL.isEmpty {
            return URL(string: "https://\(customTraceURL)")
        }
        return nil
    }

    static func readCustomRUMURL() -> URL? {
        if let customRUMURL = Bundle.main.infoDictionary![InfoPlistKey.customRUMURL] as? String,
           !customRUMURL.isEmpty {
            return URL(string: "https://\(customRUMURL)")
        }
        return nil
    }
}
