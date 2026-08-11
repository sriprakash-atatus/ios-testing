/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddCrashReporting` -> `AtatusCrashReporting`, `ddInternal` -> `AtatusInternal`, `ddLogs`
// -> `AtatusLogs`, `ddRUM` -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; renamed the `DD`
// symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

@testable import AtatusLogs
@testable import AtatusRUM
@testable import AtatusCrashReporting
@testable import AtatusCore

extension CrashReportingFeature {
    /// Mocks the Crash Reporting feature instance which doesn't load crash reports.
    public static func mockNoOp(
            core: AtatusCoreProtocol = NOPAtatusCore(),
            crashReportingPlugin: CrashReportingPlugin = NOPCrashReportingPlugin()
    ) -> Self {
        return .mockWith(
            integration: MessageBusSender(core: core),
            crashReportingPlugin: crashReportingPlugin
        )
    }

    public static func mockWith(
        integration: CrashReportSender,
        crashReportingPlugin: CrashReportingPlugin = NOPCrashReportingPlugin(),
        crashContextProvider: CrashContextProvider = CrashContextProviderMock(),
        messageReceiver: FeatureMessageReceiver = NOPFeatureMessageReceiver(),
        telemetry: Telemetry = NOPTelemetry()
    ) -> Self {
        .init(
            crashReportingPlugin: crashReportingPlugin,
            crashContextProvider: crashContextProvider,
            sender: integration,
            messageReceiver: messageReceiver,
            telemetry: telemetry
        )
    }
}

public class CrashReportingPluginMock: CrashReportingPlugin {
    /// The crash report loaded by this plugin.
    public var pendingCrashReport: ATCrashReport?
    /// If the plugin was asked to delete the crash report.
    @ReadWriteLock
    public var hasPurgedCrashReport: Bool?
    /// Custom app state data injected to the plugin.
    public var injectedContextData: Data?
    /// Custom backtrace reporter injected to the plugin.
    public var injectedBacktraceReporter: BacktraceReporting?

    public init() {}

    public func readPendingCrashReport(completion: (ATCrashReport?) -> Bool) {
        hasPurgedCrashReport = completion(pendingCrashReport)
        didReadPendingCrashReport?()
    }

    /// Notifies the `readPendingCrashReport(completion:)` return.
    public var didReadPendingCrashReport: (() -> Void)?

    public func inject(context: Data) {
        injectedContextData = context
        didInjectContext?()
    }

    /// Notifies the `inject(context:)` return.
    public var didInjectContext: (() -> Void)?

    public var backtraceReporter: BacktraceReporting? { injectedBacktraceReporter }
}

public class NOPCrashReportingPlugin: CrashReportingPlugin {
    public func readPendingCrashReport(completion: (ATCrashReport?) -> Bool) {}
    public func inject(context: Data) {}
    public var backtraceReporter: BacktraceReporting? { nil }

    public init() {}
}

public class CrashContextProviderMock: CrashContextProvider {
    public private(set) var currentCrashContext: CrashContext?
    public var onCrashContextChange: (CrashContext) -> Void

    public init(initialCrashContext: CrashContext = .mockAny()) {
        self.currentCrashContext = initialCrashContext
        self.onCrashContextChange = { _ in }
    }
}

public class CrashReportSenderMock: CrashReportSender {
    public var sentCrashReport: ATCrashReport?
    public var sentCrashContext: CrashContext?

    public init() {}

    public func send(report: ATCrashReport, with context: CrashContext) {
        sentCrashReport = report
        sentCrashContext = context
        didSendCrashReport?()
    }

    public var didSendCrashReport: (() -> Void)?

    public func send(launch: AtatusInternal.LaunchReport) {}
}

public class CrashReceiverMock: FeatureMessageReceiver {
    public var receivedCrash: Crash?

    public func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        guard case let .payload(crash as Crash) = message else {
            return false
        }
        receivedCrash = crash
        return true
    }

    public init() {}
}

extension CrashContext {
    public static func mockAny() -> CrashContext {
        return mockWith()
    }

    public static func mockWith(
        serverTimeOffset: TimeInterval = .zero,
        service: String = .mockAny(),
        env: String = .mockAny(),
        version: String = .mockAny(),
        buildNumber: String = .mockAny(),
        device: Device = .mockAny(),
        os: OperatingSystem = .mockAny(),
        sdkVersion: String = .mockAny(),
        source: String = .mockAny(),
        trackingConsent: TrackingConsent = .granted,
        userInfo: UserInfo? = .mockAny(),
        accountInfo: AccountInfo? = nil,
        networkConnectionInfo: NetworkConnectionInfo? = .mockAny(),
        carrierInfo: CarrierInfo? = .mockAny(),
        lastRUMViewEvent: RUMViewEvent? = nil,
        lastRUMSessionState: RUMSessionState? = nil,
        lastIsAppInForeground: Bool = .mockAny(),
        appLaunchDate: Date? = .mockRandomInThePast(),
        lastRUMAttributes: RUMEventAttributes? = nil,
        lastLogAttributes: LogEventAttributes? = nil
    ) -> Self {
        .init(
            serverTimeOffset: serverTimeOffset,
            service: service,
            env: env,
            version: version,
            buildNumber: buildNumber,
            device: device,
            os: os,
            sdkVersion: service,
            source: source,
            trackingConsent: trackingConsent,
            userInfo: userInfo,
            accountInfo: accountInfo,
            networkConnectionInfo: networkConnectionInfo,
            carrierInfo: carrierInfo,
            lastIsAppInForeground: lastIsAppInForeground,
            appLaunchDate: appLaunchDate,
            lastRUMViewEvent: lastRUMViewEvent,
            lastRUMSessionState: lastRUMSessionState,
            lastRUMAttributes: lastRUMAttributes,
            lastLogAttributes: lastLogAttributes
        )
    }

    public static func mockRandom() -> Self {
        .init(
            serverTimeOffset: .zero,
            service: .mockRandom(),
            env: .mockRandom(),
            version: .mockRandom(),
            buildNumber: .mockRandom(),
            device: .mockRandom(),
            os: .mockRandom(),
            sdkVersion: .mockRandom(),
            source: .mockRandom(),
            trackingConsent: .granted,
            userInfo: .mockRandom(),
            accountInfo: .mockRandom(),
            networkConnectionInfo: .mockRandom(),
            carrierInfo: .mockRandom(),
            lastIsAppInForeground: .mockRandom(),
            appLaunchDate: .mockRandomInThePast(),
            lastRUMViewEvent: .mockRandom(),
            lastRUMSessionState: .mockRandom(),
            lastRUMAttributes: .mockRandom(),
            lastLogAttributes: .mockRandom()
        )
    }

    public var data: Data { try! JSONEncoder.dd.default().encode(self) }
}
