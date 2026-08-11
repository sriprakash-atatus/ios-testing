/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

#if os(iOS)
import Foundation

/// Bundles SR records with their RUM context and other information required for preparing SR upload.
///
/// `EnrichedRecord` are produced by `Processor` and written to `AtatusCore` storage.
/// By saving records soon after they are created we ensure that replay data can be consistently uploaded
/// even if the session was suddenly terminated by a crash.
///
/// `EnrichedRecord` conforms to `Encodable` so it can be encoded by `AtatusCore`.
/// For decoding `EnrichedRecord` information, see `EnrichedRecordJSON` type.
internal struct EnrichedRecord: Encodable {
    /// The RUM application ID of all records.
    let applicationID: String
    /// The RUM session ID of all records.
    let sessionID: String
    /// The RUM view ID of all records.
    let viewID: String
    /// Records enriched with further information.
    let records: [SRRecord]

    enum CodingKeys: String, CodingKey {
        case records
        case applicationID
        case sessionID
        case viewID
    }

    init(context: Recorder.Context, records: [SRRecord]) {
        self.applicationID = context.applicationID
        self.sessionID = context.sessionID
        self.viewID = context.viewID
        self.records = records
    }
}

#endif
