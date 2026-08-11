/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// Simple `DateProvider` mock that returns given date.
public final class DateProviderMock: DateProvider {
    private let _now: ReadWriteLock<Date>

    public init(now: Date = Date()) {
        self._now = .init(wrappedValue: now)
    }

    public var now: Date {
        get { _now.wrappedValue }
        set { _now.wrappedValue = newValue }
    }
}

/// `DateProvider` mock returning consecutive dates in custom intervals, starting from given reference date.
public final class RelativeDateProvider: DateProvider {
    private let date: ReadWriteLock<Date>
    internal let timeInterval: TimeInterval

    private init(date: Date, timeInterval: TimeInterval) {
        self.date = .init(wrappedValue: date)
        self.timeInterval = timeInterval
    }

    public convenience init(using date: Date = Date()) {
        self.init(date: date, timeInterval: 0)
    }

    public convenience init(startingFrom referenceDate: Date = Date(), advancingBySeconds timeInterval: TimeInterval = 0) {
        self.init(date: referenceDate, timeInterval: timeInterval)
    }

    /// Returns current date and advances next date by `timeInterval`.
    public var now: Date {
        defer { date.mutate { $0.addTimeInterval(timeInterval) } }
        return date.wrappedValue
    }

    /// Pushes time forward by given number of seconds.
    public func advance(bySeconds seconds: TimeInterval) {
        date.mutate { $0.addTimeInterval(seconds) }
    }
}
