/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

@objc
public class OT: NSObject {
    @objc public static let formatTextMap = "OTFormatTextMap"
}

/// Corresponds to: https://github.com/opentracing/opentracing-objc/blob/master/Pod/Classes/OTTracer.h
@objc(OTTracer)
@_spi(objc)
public protocol objc_OTTracer {
    func startSpan(_ operationName: String) -> objc_OTSpan
    func startSpan(_ operationName: String, tags: NSDictionary?) -> objc_OTSpan
    func startSpan(_ operationName: String, childOf parent: objc_OTSpanContext?) -> objc_OTSpan
    func startSpan(_ operationName: String, childOf parent: objc_OTSpanContext?, tags: NSDictionary?) -> objc_OTSpan
    func startSpan(_ operationName: String, childOf parent: objc_OTSpanContext?, tags: NSDictionary?, startTime: Date?) -> objc_OTSpan
    func startRootSpan(_ operationName: String, tags: NSDictionary?, startTime: Date?, customSampleRate: NSNumber?) -> objc_OTSpan
    func inject(_ spanContext: objc_OTSpanContext, format: String, carrier: Any) throws
    func extractWithFormat(_ format: String, carrier: Any) throws
}
