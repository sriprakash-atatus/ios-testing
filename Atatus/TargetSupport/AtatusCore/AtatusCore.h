/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

#import <Foundation/Foundation.h>

//! Project version number for Atatus.
FOUNDATION_EXPORT double AtatusVersionNumber;

//! Project version string for Atatus.
FOUNDATION_EXPORT const unsigned char AtatusVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Atatus/PublicHeader.h>

#import "ObjcAppLaunchHandler.h"
#import "ObjcExceptionHandler.h"
