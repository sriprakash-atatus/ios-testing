/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import OpenTelemetryApi
import AtatusInternal

extension OpenTelemetryApi.TraceId {
    /// Converts OpenTelemetry `TraceId` to Atatus `TraceID`.
    /// - Returns: Atatus `TraceID` with only higher order bits considered.
    func toAtatus() -> TraceID {
        return .init(idHi: self.idHi, idLo: self.idLo)
    }
}
