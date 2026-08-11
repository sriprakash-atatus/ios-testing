/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Data scrubbing interface.
///
/// It takes `LogEvent` and call the callback with the modified `LogEvent`.
/// Not calling the callback will drop the event.
public protocol LogEventMapper {
    /// Maps a log event for data scrubbing.
    ///
    /// This method allow async call to the callback closure.
    ///
    /// - Parameters:
    ///   - event: The event to map.
    ///   - callback: The mapper callback with the new event.
    func map(event: LogEvent, callback: @escaping (LogEvent) -> Void)
}

/// Synchronous log event mapper.
///
/// The class take a flat-map closure parameter for event scrubbing
internal final class SyncLogEventMapper: LogEventMapper {
    let mapper: (LogEvent) -> LogEvent?

    init(_ mapper: @escaping (LogEvent) -> LogEvent?) {
        self.mapper = mapper
    }

    func map(event: LogEvent, callback: @escaping (LogEvent) -> Void) {
        mapper(event).map(callback)
    }
}
