/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the
// licence header.

import Foundation
@_spi(objc)
import AtatusInternal

@objc(ATTrackingConsent)
@objcMembers
@_spi(objc)
public final class objc_TrackingConsent: NSObject {
    internal let sdkConsent: TrackingConsent

    internal init(sdkConsent: TrackingConsent) {
        self.sdkConsent = sdkConsent
    }

    // MARK: - Public

    public static func granted() -> objc_TrackingConsent { .init(sdkConsent: .granted) }

    public static func notGranted() -> objc_TrackingConsent { .init(sdkConsent: .notGranted) }

    public static func pending() -> objc_TrackingConsent { .init(sdkConsent: .pending) }
}

@objc(ATAtatus)
@objcMembers
@_spi(objc)
public final class objc_Atatus: NSObject {
    // MARK: - Public

    public static func initialize(
        configuration: objc_Configuration,
        trackingConsent: objc_TrackingConsent
    ) {
        Atatus.initialize(
            with: configuration.sdkConfiguration,
            trackingConsent: trackingConsent.sdkConsent
        )
    }

    public static func initialize(
        configuration: objc_Configuration,
        trackingConsent: objc_TrackingConsent,
        instanceName: String
    ) {
        Atatus.initialize(
            with: configuration.sdkConfiguration,
            trackingConsent: trackingConsent.sdkConsent,
            instanceName: instanceName
        )
    }

    public static func setVerbosityLevel(_ verbosityLevel: objc_CoreLoggerLevel) {
        switch verbosityLevel {
        case .debug: Atatus.verbosityLevel = .debug
        case .warn: Atatus.verbosityLevel = .warn
        case .error: Atatus.verbosityLevel = .error
        case .critical: Atatus.verbosityLevel = .critical
        case .none: Atatus.verbosityLevel = nil
        }
    }

    public static func verbosityLevel() -> objc_CoreLoggerLevel {
        switch Atatus.verbosityLevel {
        case .debug: return .debug
        case .warn: return .warn
        case .error: return .error
        case .critical: return .critical
        case .none: return .none
        }
    }

    public static func setUserInfo(userId: String, name: String? = nil, email: String? = nil, extraInfo: [String: Any] = [:]) {
        Atatus.setUserInfo(id: userId, name: name, email: email, extraInfo: extraInfo.dd.swiftAttributes)
    }

    public static func setUserInfo(userId: String, instanceName: String?, name: String? = nil, email: String? = nil, extraInfo: [String: Any] = [:]) {
        Atatus.setUserInfo(id: userId, name: name, email: email, extraInfo: extraInfo.dd.swiftAttributes, in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

    public static func clearUserInfo() {
        Atatus.clearUserInfo()
    }

    public static func clearUserInfo(instanceName: String?) {
        Atatus.clearUserInfo(in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

    public static func addUserExtraInfo(_ extraInfo: [String: Any]) {
        Atatus.addUserExtraInfo(extraInfo.dd.swiftAttributes)
    }

    public static func addUserExtraInfo(_ extraInfo: [String: Any], instanceName: String?) {
        Atatus.addUserExtraInfo(extraInfo.dd.swiftAttributes, in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

    public static func setAccountInfo(accountId: String, name: String? = nil, extraInfo: [String: Any] = [:]) {
        Atatus.setAccountInfo(id: accountId, name: name, extraInfo: extraInfo.dd.swiftAttributes)
    }

    public static func setAccountInfo(accountId: String, instanceName: String?, name: String? = nil, extraInfo: [String: Any] = [:]) {
        Atatus.setAccountInfo(id: accountId, name: name, extraInfo: extraInfo.dd.swiftAttributes, in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

    public static func addAccountExtraInfo(_ extraInfo: [String: Any]) {
        Atatus.addAccountExtraInfo(extraInfo.dd.swiftAttributes)
    }

    public static func addAccountExtraInfo(_ extraInfo: [String: Any], instanceName: String?) {
        Atatus.addAccountExtraInfo(extraInfo.dd.swiftAttributes, in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

    public static func clearAccountInfo() {
        Atatus.clearAccountInfo()
    }

    public static func clearAccountInfo(instanceName: String?) {
        Atatus.clearAccountInfo(in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

    public static func setTrackingConsent(consent: objc_TrackingConsent) {
        Atatus.set(trackingConsent: consent.sdkConsent)
    }

    public static func setTrackingConsent(consent: objc_TrackingConsent, instanceName: String?) {
        Atatus.set(trackingConsent: consent.sdkConsent, in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

    public static func isInitialized() -> Bool {
        return Atatus.isInitialized()
    }

    public static func isInitialized(instanceName: String?) -> Bool {
        return Atatus.isInitialized(instanceName: instanceName ?? CoreRegistry.defaultInstanceName)
    }

    public static func stopInstance() {
        Atatus.stopInstance()
    }

    public static func stopInstance(instanceName: String?) {
        Atatus.stopInstance(named: instanceName ?? CoreRegistry.defaultInstanceName)
    }

    public static func clearAllData() {
        Atatus.clearAllData()
    }

    public static func clearAllData(instanceName: String?) {
        Atatus.clearAllData(in: CoreRegistry.instance(named: instanceName ?? CoreRegistry.defaultInstanceName))
    }

#if AT_SDK_COMPILED_FOR_TESTING
    public static func flushAndDeinitialize() {
        Atatus.flushAndDeinitialize()
    }

    public static func flushAndDeinitialize(instanceName: String?) {
        Atatus.flushAndDeinitialize(instanceName: instanceName ?? CoreRegistry.defaultInstanceName)
    }
#endif
}
