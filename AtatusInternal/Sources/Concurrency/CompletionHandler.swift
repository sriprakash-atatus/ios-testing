/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Alias from completion closure with no parameter.
public typealias CompletionHandler = () -> Void

/// No-op completion function.
///
/// Using a function prevent allocating a closure when applying a placeholder.
public func NOPCompletionHandler() {}
