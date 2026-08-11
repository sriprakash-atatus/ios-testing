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

extension OpenTelemetryApi.SpanId {
    /// Converts OpenTelemetry `SpanId` to Atatus `SpanID`.
    /// - Returns: Atatus `SpanID`.
    func toAtatus() -> SpanID {
        var data = Data(count: 8)
        self.copyBytesTo(dest: &data, destOffset: 0)
        let integerLiteral = UInt64(bigEndian: data.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) })
        return .init(integerLiteral: integerLiteral)
    }
}
