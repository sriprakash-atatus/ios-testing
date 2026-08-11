/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#import <TargetConditionals.h>

#if !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomObjcViewController : UIViewController

@end

NS_ASSUME_NONNULL_END

#endif
