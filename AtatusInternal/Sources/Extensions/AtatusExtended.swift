/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// Type that acts as a generic extension point for all `AtatusExtended` types.
public struct AtatusExtension<ExtendedType> {
    /// Stores the type or meta-type of any extended type.
    public private(set) var type: ExtendedType

    /// Create an instance from the provided value.
    ///
    /// - Parameter type: Instance being extended.
    public init(_ type: ExtendedType) {
        self.type = type
    }
}

/// Protocol describing the `dd` extension points for Atatus extended types.
public protocol AtatusExtended {
    /// Type being extended.
    associatedtype ExtendedType

    /// Static Atatus extension point.
    static var dd: AtatusExtension<ExtendedType>.Type { get set }
    /// Instance Atatus extension point.
    var dd: AtatusExtension<ExtendedType> { get set }
}

extension AtatusExtended {
    /// Static Atatus extension point.
    public static var dd: AtatusExtension<Self>.Type {
        get { AtatusExtension<Self>.self }
        set {}
    }

    /// Instance Atatus extension point.
    public var dd: AtatusExtension<Self> {
        get { AtatusExtension(self) }
        set {}
    }
}

extension Array: AtatusExtended {}
extension Dictionary: AtatusExtended {}
