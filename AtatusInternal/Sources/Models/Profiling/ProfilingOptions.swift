/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

public struct ProfilingOptions: OperationOptions {
    // The profiling sample rate for operations. Must be a value between `0` and `100`.
    public let sampleRate: SampleRate

    public init(sampleRate: SampleRate) {
        self.sampleRate = sampleRate
    }
}
