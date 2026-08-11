/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// An extension for FixedWidthInteger that provides a convenient API for
/// converting numeric values into different units of data storage, such as
/// bytes, kilobytes, megabytes, and gigabytes.
public extension FixedWidthInteger {
    /// A private property that represents the base unit (1024) used for
    /// converting between data storage units.
    private var base: Self { 1_024 }

    /// A property that converts the given numeric value into kilobytes.
    var KB: Self { return self.multipliedReportingOverflow(by: base).partialValue }

    /// A property that converts the given numeric value into megabytes.
    var MB: Self { return self.KB.multipliedReportingOverflow(by: base).partialValue }

    /// A property that converts the given numeric value into gigabytes.
    var GB: Self { return self.MB.multipliedReportingOverflow(by: base).partialValue }

    /// A helper property that returns the current value as a direct representation in bytes.
    var bytes: Self { return self }

    func asUInt64() -> UInt64 { UInt64(self) }

    func asUInt32() -> UInt32 { UInt32(self) }
}
