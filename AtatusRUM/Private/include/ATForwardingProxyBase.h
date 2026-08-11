/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `__dd_private_*` ObjC symbols to `__atatus_private_*`;
// rebranded the licence header.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Safe ObjC forwarding base class for proxy types whose forwarding target (a weak reference
/// to the original delegate) can disappear between when UIKit caches `responds(to:)` and
/// when it dispatches the cached selector — typically during view-controller teardown.
///
/// Without this base class, a stale dispatch raises `NSInvalidArgumentException`
/// ("unrecognized selector"). This base class returns a valid `NSMethodSignature` so the
/// runtime can construct an `NSInvocation`, then silently drops the invocation in
/// `forwardInvocation:` if the target is gone.
///
/// Subclasses override `forwardingTargetOrNil` to return the current target (or `nil` if gone).
@interface __atatus_private_DDForwardingProxyBase : NSObject

/// Subclasses override to return the current forwarding target (may be `nil`).
/// The default implementation returns `nil`.
- (nullable id)forwardingTargetOrNil;

@end

NS_ASSUME_NONNULL_END
