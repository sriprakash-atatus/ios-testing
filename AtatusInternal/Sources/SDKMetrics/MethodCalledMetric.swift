/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Definition of "Method Called" telemetry.
public enum MethodCalledMetric {
    /// The name of this metric, included in telemetry log.
    /// Note: the "[Mobile Metric]" prefix is added when sending this telemetry in RUM.
    public static let name = "Method Called"
    /// Metric type value.
    public static let typeValue = "method called"

    /// The key for operation name.
    public static let operationName = "operation_name"
    /// The key for caller class.
    public static let callerClass = "caller_class"
    /// The key for is successful.
    public static let isSuccessful = "is_successful"
    /// The key for execution time.
    public static let executionTime = "execution_time"
}
