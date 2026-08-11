/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import AtatusInternal

// MARK: - TopLevelReflector
/// Protocol defining an interface for reflection-based object inspection.
/// `TopLevelReflector` provides a consistent way to navigate through object structures
/// by traversing paths of properties.
internal protocol TopLevelReflector {
    /// Attempts to find a descendant at the specified path.
    func descendant(_ paths: [ReflectionMirror.Path]) -> Any?
}

// MARK: - Reflector
extension ReflectionMirror: TopLevelReflector {}
