/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

internal protocol RUMScope: AnyObject {
    /// Container bundling dependencies for this scope.
    var dependencies: RUMScopeDependencies { get }

    /// Processes given command. Returns:
    /// * `true` if the scope should be kept open.
    /// * `false` if the scope should be closed.
    func process(command: RUMCommand, context: AtatusContext, writer: Writer) -> Bool
}

extension RUMScope {
    /// Propagates given `command` and manages its lifecycle by returning `nil` if it gets closed.
    ///
    /// Returns `self`  to be kept open, `nil` if it requests to close.
    func scope(byPropagating command: RUMCommand, context: AtatusContext, writer: Writer) -> Self? {
        process(command: command, context: context, writer: writer) ? self : nil
    }
}

extension Array where Element: RUMScope {
    /// Propagates given `command` through this array of scopes and manages their lifecycle by
    /// filtering scopes that get closed.
    ///
    /// Returns the `childScopes` array by removing scopes which requested to be closed.
    func scopes(byPropagating command: RUMCommand, context: AtatusContext, writer: Writer) -> [Element] {
        return filter { scope in
            scope.process(command: command, context: context, writer: writer)
        }
    }
}
