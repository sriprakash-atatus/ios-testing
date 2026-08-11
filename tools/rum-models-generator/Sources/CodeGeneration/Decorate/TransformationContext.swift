/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Manages stack of nested types for their transformation.
public class TransformationContext<T> {
    private var stack: [T] = []

    func enter(_ type: T) {
        stack.append(type)
    }

    func leave() {
        stack = stack.dropLast()
    }

    public var current: T? { stack.last }
    public var parent: T? { stack.dropLast().last }

    public func predecessor(matching predicate: (T) -> Bool) -> T? {
        return stack.reversed().first { predicate($0) }
    }
}
