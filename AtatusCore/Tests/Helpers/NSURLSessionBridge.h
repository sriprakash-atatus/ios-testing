/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#import <Foundation/Foundation.h>

@interface NSURLSessionBridge : NSObject

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

- (id)init: (NSURLSession*)session;

@end
