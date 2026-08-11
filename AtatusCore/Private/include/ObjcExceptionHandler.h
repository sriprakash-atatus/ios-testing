/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed the `__dd_private_*` ObjC symbols to `__atatus_private_*`;
// rebranded the licence header.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface __atatus_private_ObjcExceptionHandler : NSObject

+ (BOOL)catchException:(void(NS_NOESCAPE ^)(void))tryBlock error:(__autoreleasing NSError **)error
    NS_SWIFT_NAME(rethrow(_:));

@end

NS_ASSUME_NONNULL_END
