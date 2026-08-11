/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Represents a single test action to be performed in an `AppRun`.
internal struct AppRunStep: Hashable {
    /// Unique identifier used for distinguishing steps.
    let uuid = UUID()

    /// The action to perform, provided with an `AppRunner` context.
    let perform: (AppRunner) -> Void

    /// Creates a new step with the given execution closure.
    /// - Parameter perform: The closure that defines the step logic using the `AppRunner`.
    init(_ perform: @escaping (AppRunner) -> Void) {
        self.perform = perform
    }

    // MARK: – Equatable

    static func == (lhs: AppRunStep, rhs: AppRunStep) -> Bool { lhs.uuid == rhs.uuid }

    // MARK: – Hashable

    func hash(into hasher: inout Hasher) { hasher.combine(uuid) }
}
