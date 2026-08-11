/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; repointed the intake host at the Atatus site; rebranded the `dd` name
// to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

extension Atatus: InternalExtended {}

/// This extension exposes internal methods that are used by other Atatus modules and cross platform
/// frameworks. It is not meant for public use.
///
/// DO NOT USE this extension or its methods if you are not working on the internals of the Atatus SDK
/// or one of the cross platform frameworks.
///
/// Methods, members, and functionality of this class  are subject to change without notice, as they
/// are not considered part of the public interface of the Atatus SDK.
extension InternalExtension where ExtendedType == Atatus {
    /// Internal telemetry proxy.
    public static var telemetry: _TelemetryProxy {
        .init(telemetry: CoreRegistry.default.telemetry)
    }

    /// Changes the `version` used for [Unified Service Tagging](https://www.atatus.com/docs/).
    public static func set(customVersion: String) {
        guard let core = CoreRegistry.default as? AtatusCore else {
            return
        }

        core.applicationVersionPublisher.version = customVersion
    }
}

public struct _TelemetryProxy {
    let telemetry: Telemetry

    /// See Telementry.debug
    public func debug(id: String, message: String) {
        telemetry.debug(id: id, message: message)
    }

    /// See Telementry.error
    public func error(id: String, message: String, kind: String?, stack: String?) {
        telemetry.error(id: id, message: message, kind: kind ?? "unknown", stack: stack ?? "unknown")
    }
}

extension Atatus.Configuration: InternalExtended { }
extension InternalExtension where ExtendedType == Atatus.Configuration {
    /// Sets additional configuration attributes.
    /// This can be used to tweak internal features of the SDK.
    public var additionalConfiguration: [String: Any] {
        get { type.additionalConfiguration }
        set { type.additionalConfiguration = newValue}
    }
}
