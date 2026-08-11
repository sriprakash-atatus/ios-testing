/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

/// Extension that provides cross-platform libraries with additional Internal-only capabilities.
/// It's Objective-C compatible, mainly for KMP support.
///
/// Note: It only works for single core setup, relying on `CoreRegistry.default` existence.
@objc(ATCrossPlatformExtension)
@objcMembers
@_spi(Internal)
public final class CrossPlatformExtension: NSObject {
    private static var contextSharingTransformer: ContextSharingTransformer?

    /// Subscribes to shared context updates.
    ///
    /// The provided closure will be called immediately with the current context (or `nil` if no context yet),
    /// and subsequently whenever the context changes. It lazy loads static instance of `ContextSharingTransformer`
    /// and registers `ContextSharingFeature`.
    ///
    /// - Parameter toSharedContext: A closure that receives `SharedContext` updates. Called on context changes.
    @objc
    public static func subscribe(toSharedContext: @escaping (SharedContext?) -> Void) {
        if Self.contextSharingTransformer == nil {
            let core = CoreRegistry.default
            let contextSharingTransformer = ContextSharingTransformer()
            try? core.register(feature: ContextSharingFeature(messageReceiver: contextSharingTransformer))
            Self.contextSharingTransformer = contextSharingTransformer
        }
        contextSharingTransformer?.publish(to: toSharedContext)
    }

    /// Drops the subscription to `SharedContext`, and removes the static refrence.
    ///
    /// Note: that it doesn't remove the registered feature.
    @objc
    public static func unsubscribeFromSharedContext() {
        contextSharingTransformer?.cancel()
        contextSharingTransformer = nil
    }
}
