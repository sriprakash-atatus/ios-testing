/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "AtatusCoreTests-Swift.h"

/// This code runs when the `AtatusTests` bundle is loaded into memory and tests start.
/// Reference: https://developer.apple.com/documentation/objectivec/nsobject/1418815-load
__attribute__((constructor)) static void initialize_FrameworkLoadHandler(void) {
    [AtatusTestsObserver startObserving];
}
