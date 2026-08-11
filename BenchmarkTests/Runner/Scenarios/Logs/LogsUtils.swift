/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddLogs` -> `AtatusLogs`; rebranded the licence
// header.

import AtatusLogs
import Foundation

var logLevels: [(String, LogLevel)] = [
    ("DEBUG", .debug),
    ("INFO", .info),
    ("NOTICE", .notice),
    ("WARN", .warn),
    ("ERROR", .error),
    ("CRITICAL", .critical),
]

var payloadSizes: [(String, [String: Encodable])] = [
    ("Small", [
        "log_type": "simple",
    ]),
    ("Medium", [
        "user": [
            "id": UUID().uuidString,
            "name": "John Doe",
            "email": "johndoe@example.com",
        ],
        "device": [
            "type": "iPhone",
            "os": "iOS 17.0",
        ],
        "log_type": "user_event",
    ]),
    ("Large", [
        "log_type": "user_event",
        "session": [
            "id": UUID().uuidString,
            "startTime": "2024-02-27T12:00:00Z",
            "duration": "2450",
        ],
        "user": [
            "id": "a1b2c3d4-e5f6-7g8h-9i0j-k1l2m3n4o5p6",
            "name": "John Doe",
            "email": "johndoe@example.com",
        ],
        "location": [
            "city": "San Francisco",
            "country": "USA",
        ],
        "device": [
            "model": "iPhone 15 Pro",
            "os": "iOS 17.2",
            "battery": "80%",
        ],
        "network": [
            "type": "WiFi",
            "carrier": "Verizon",
        ],
        "errorStack": [
            "stackTrace": "Error at module XYZ -> function ABC",
            "crashType": "NullPointerException",
        ],
    ]),
]
