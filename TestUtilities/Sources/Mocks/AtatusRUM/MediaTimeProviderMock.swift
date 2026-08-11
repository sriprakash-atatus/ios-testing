/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import AtatusInternal
import Foundation
import QuartzCore

/// Mock to return media uptime.
public final class MediaTimeProviderMock: CACurrentMediaTimeProvider {
    private let _current: ReadWriteLock<CFTimeInterval>

    #if os(watchOS)
    public init(current: CFTimeInterval = 0) {
        self._current = .init(wrappedValue: current)
    }
    #else
    public init(current: CFTimeInterval = CACurrentMediaTime()) {
        self._current = .init(wrappedValue: current)
    }
    #endif

    public var current: CFTimeInterval {
        get { _current.wrappedValue }
        set { _current.wrappedValue = newValue }
    }
}
