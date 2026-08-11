/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Struct representing a single event.
public struct Event: Equatable {
    /// Data representing the event.
    public let data: Data

    /// Metadata associated with the event.
    /// Metadata is optional and may be `nil` but of very small size.
    /// This allows us to skip resource intensive operations in case such
    /// as filtering of the events.
    public let metadata: Data?

    public init(data: Data, metadata: Data? = nil) {
        self.data = data
        self.metadata = metadata
    }
}
