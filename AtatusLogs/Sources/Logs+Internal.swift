/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

extension Logs: InternalExtended {}

extension InternalExtension where ExtendedType == Logs {
    /// Check whether `Logs` has been enabled for a specific SDK instance.
    /// 
    /// - Parameters:
    ///    - in: the core to check
    ///
    /// - Returns: true if `Logs` has been enabled for the supplied core.
    public static func isEnabled(in core: AtatusCoreProtocol = CoreRegistry.default) -> Bool {
        return core.get(feature: LogsFeature.self) != nil
    }
}
