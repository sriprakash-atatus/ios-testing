/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CrashReportingObjcHelpers : NSObject

- (void) throwUncaughtNSException;
- (void) dereferenceNullPointer;

@end

NS_ASSUME_NONNULL_END
