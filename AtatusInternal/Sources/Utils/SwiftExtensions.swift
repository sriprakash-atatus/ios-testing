/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; renamed `dd*` members to `at*`; rebranded the licence header.

import Foundation

// MARK: - Optional
public struct ATOptionalExtension<Wrapped> {
    private let optional: Wrapped?

    init(_ optional: Wrapped?) {
        self.optional = optional
    }

    public func ifNotNil(_ closure: (Wrapped) throws -> Void) rethrows {
        if case .some(let unwrappedValue) = optional {
            try closure(unwrappedValue)
        }
    }
}

extension Optional {
    public var dd: ATOptionalExtension<Wrapped> {
        ATOptionalExtension(self)
    }
}

// MARK: - Double / TimeInterval
extension Double: AtatusExtended {}
extension AtatusExtension where ExtendedType == Double {
    public func divideIfNotZero(by divider: Double) -> Double? {
        if divider == 0 {
            return nil
        }
        return type / divider
    }

    public var inverted: Double {
        return type == 0 ? 0 : 1 / type
    }

    // TimeInterval conversion methods

    /// `TimeInterval` represented in milliseconds (capped to `.min` or `.max` respectively to its sign).
    public var toMilliseconds: UInt64 {
        let milliseconds = type * 1_000
        return UInt64.atWithNoOverflow(milliseconds)
    }

    /// `TimeInterval` represented in milliseconds (capped to `.min` or `.max` respectively to its sign).
    public var toInt64Milliseconds: Int64 {
        let milliseconds = type * 1_000
        return Int64.atWithNoOverflow(milliseconds)
    }

    /// `TimeInterval` represented in nanoseconds (capped to `.min` or `.max` respectively to its sign).
    /// Note: as `TimeInterval` yields sub-millisecond precision the nanoseconds precision will be lost.
    public var toNanoseconds: UInt64 {
        let nanoseconds = type * 1_000_000_000
        return UInt64.atWithNoOverflow(nanoseconds)
    }

    /// `TimeInterval` represented in nanoseconds (capped to `.min` or `.max` respectively to its sign).
    /// Note: as `TimeInterval` yields sub-millisecond precision the nanoseconds precision will be lost.
    public var toInt64Nanoseconds: Int64 {
        let nanoseconds = type * 1_000_000_000
        return Int64.atWithNoOverflow(nanoseconds)
    }
}

// TimeInterval factory methods
extension TimeInterval {
    public static func atFromMilliseconds(_ milliseconds: Int64) -> TimeInterval {
        return Double(milliseconds) / 1_000
    }

    public static func atFromNanoseconds(_ nanoseconds: Int64) -> TimeInterval {
        return Double(nanoseconds) / 1_000_000_000
    }
}

// MARK: - UUID
extension UUID: AtatusExtended {}
extension AtatusExtension where ExtendedType == UUID {
    /// An UUID with all zeroes (`00000000-0000-0000-0000-000000000000`).
    /// Used to represent "null" in types that cannot be given a proper UUID (e.g. rejected RUM session).
    public static var nullUUID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()
    }
}

// MARK: - Safe floating point to integer conversion
public enum FixedWidthIntegerError<T: BinaryFloatingPoint>: Error {
    case overflow(overflowingValue: T)
}

extension FixedWidthInteger {
    /* NOTE: RUMM-182
     Self(:) is commonly used for conversion, however it fatalError() in case of conversion failure
     Self(exactly:) does the exact same thing internally yet it returns nil instead of fatalError()
     It is not trivial to guess if the conversion would fail or succeed, therefore we use Self(exactly:)
     so that we don't need to guess in order to save the app from crashing

     IMPORTANT: If you pass floatingPoint to Self(exactly:) without rounded(), it may return nil
     */
    public static func atWithReportingOverflow<T: BinaryFloatingPoint>(_ floatingPoint: T) throws -> Self {
        guard let converted = Self(exactly: floatingPoint.rounded()) else {
            throw FixedWidthIntegerError<T>.overflow(overflowingValue: floatingPoint)
        }
        return converted
    }

    /// Converts floating point value to fixed width integer with preventing overflow (and crash).
    /// In case of overflow, the value is converted to `.min` or `.max` respectively to its sign.
    /// - Parameter floatingPoint: the value to convert
    public static func atWithNoOverflow<T: BinaryFloatingPoint>(_ floatingPoint: T) -> Self {
        if let converted = Self(exactly: floatingPoint.rounded()) {
            return converted
        } else { // overflow occurred
            switch floatingPoint.sign {
            case .minus: return .min
            case .plus: return .max
            }
        }
    }
}

// MARK: - Collection
extension AtatusExtension where ExtendedType: Collection {
    /// Safe collection subscript that returns nil instead of crashing for out-of-bounds access.
    public subscript (safe index: ExtendedType.Index) -> ExtendedType.Element? {
        guard index >= type.startIndex && index < type.endIndex else {
            return nil
        }
        return type[index]
    }
}

// MARK: - Bundle
extension Bundle: AtatusExtended {}
extension AtatusExtension where ExtendedType == Bundle {
    /// Returns `true` when `self` represents the `SwiftUI` framework bundle.
    public var isSwiftUI: Bool {
        return type.bundleURL.lastPathComponent == "SwiftUI.framework"
    }

    /// Returns `true` when `self` represents the `UIKit` framework bundle.
    public var isUIKit: Bool {
        return type.bundleURL.lastPathComponent == "UIKitCore.framework"
    }
}
