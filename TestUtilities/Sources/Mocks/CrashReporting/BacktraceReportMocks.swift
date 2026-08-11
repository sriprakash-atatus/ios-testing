/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import AtatusInternal

extension BacktraceReport: AnyMockable, RandomMockable {
    public static func mockAny() -> BacktraceReport {
        return .mockWith()
    }

    public static func mockRandom() -> BacktraceReport {
        return BacktraceReport(
            stack: .mockRandom(),
            threads: .mockRandom(),
            binaryImages: .mockRandom(),
            wasTruncated: .mockRandom()
        )
    }

    public static func mockWith(
        stack: String = .mockAny(),
        threads: [ATThread] = .mockAny(),
        binaryImages: [BinaryImage] = .mockAny(),
        wasTruncated: Bool = .mockAny()
    ) -> BacktraceReport {
        return BacktraceReport(
            stack: stack,
            threads: threads,
            binaryImages: binaryImages,
            wasTruncated: wasTruncated
        )
    }
}
