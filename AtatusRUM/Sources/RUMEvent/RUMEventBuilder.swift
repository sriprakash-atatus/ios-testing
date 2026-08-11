/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

internal class RUMEventBuilder {
    let eventsMapper: RUMEventsMapper
    let sanitizer = RUMEventSanitizer()

    init(eventsMapper: RUMEventsMapper) {
        self.eventsMapper = eventsMapper
    }

    func build<Event>(from event: Event) -> Event? where Event: RUMSanitizableEvent {
        guard let transformedEvent = eventsMapper.map(event: event) else {
            return nil
        }

        return sanitizer.sanitize(event: transformedEvent)
    }
}
