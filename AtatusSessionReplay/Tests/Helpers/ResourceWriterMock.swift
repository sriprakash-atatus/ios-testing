/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

@testable import AtatusSessionReplay

class ResourceWriterMock: ResourcesWriting {
    var resources: [[EnrichedResource]] = []

    func write(resources: [EnrichedResource]) {
        self.resources.append(resources)
    }
}
