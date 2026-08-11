/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import AtatusInternal

/// A description of the RUM Action returned from the `UIKitRUMActionsPredicate`.
public struct RUMAction {
    /// The RUM Action name, appearing as `ACTION NAME` in RUM Explorer. If no name is given, default one will be used.
    public var name: String

    /// Additional attributes to associate with the RUM Action.
    public var attributes: [AttributeKey: AttributeValue]

    /// Initializes the RUM Action description.
    /// - Parameters:
    ///   - name: the RUM Action name, appearing as `Action NAME` in RUM Explorer. If no name is given, default one will be used.
    ///   - attributes: additional attributes to associate with the RUM Action.
    public init(name: String, attributes: [AttributeKey: AttributeValue] = [:]) {
        self.name = name
        self.attributes = attributes
    }
}
