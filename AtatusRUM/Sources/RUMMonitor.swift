/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; rebranded the `dd` name to `Atatus` in
// comments and docs; rebranded the licence header.

import AtatusInternal

/// A class for manual interaction with the RUM feature. It records RUM events that are sent to Atatus RUM.
///
/// There can be only one active RUM monitor for certain instance of Atatus SDK. It gets enabled along with
/// the call to `RUM.enable(with:in:)`:
///
///     import AtatusRUM
///
///     // Enable RUM feature:
///     RUM.enable(with: configuration)
///
///     // Use RUM monitor:
///     RUMMonitor.shared().startView(...)
///
public class RUMMonitor {
    /// Obtains the RUM monitor for manual interaction with the RUM feature.
    ///
    /// It requires `RUM.enable(with:in:)` to be called first - otherwise it will return no-op implementation.
    /// - Parameter core: the instance of Atatus SDK the RUM feature was enabled in (global instance by default)
    /// - Returns: the RUM monitor
    public static func shared(in core: AtatusCoreProtocol = CoreRegistry.default) -> RUMMonitorProtocol {
        do {
            guard !(core is NOPAtatusCore) else {
                throw ProgrammerError(
                    description: "Atatus SDK must be initialized and RUM feature must be enabled before calling `RUMMonitor.shared(in:)`."
                )
            }
            guard let feature = core.get(feature: RUMFeature.self) else {
                throw ProgrammerError(
                    description: "RUM feature must be enabled before calling `RUMMonitor.shared(in:)`."
                )
            }

            return feature.monitor
        } catch {
            consolePrint("\(error)", .error)
            return NOPMonitor()
        }
    }
}
