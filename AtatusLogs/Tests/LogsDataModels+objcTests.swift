/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddLogs`
// -> `AtatusLogs`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@_spi(objc)
@testable import AtatusLogs

class LogsDataModels_objcTests: XCTestCase {
    func testSwiftDDDevice_isEqualToObjCDDDevice() throws {
        // Given
        let swiftDevice: Device = .mockRandom()
        let objcLogEvent = objc_LogEvent(swiftModel: .mockWith(device: swiftDevice))
        let objcDDDevice = objc_LogEventDDDevice(root: objcLogEvent)

        // Then
        XCTAssertEqual(swiftDevice.architecture, objcDDDevice.architecture)
        XCTAssertEqual(swiftDevice.architecture, objcLogEvent.dd.device.architecture)
    }

    func testSwiftDevice_isEqualToObjCDevice() throws {
        // Given
        let swiftDevice: Device = .mockRandom()
        let objcLogEvent = objc_LogEvent(swiftModel: .mockWith(device: swiftDevice))
        let objcDevice = objc_LogEventDevice(root: objcLogEvent)

        // Then
        XCTAssertEqual(swiftDevice.architecture, objcDevice.architecture)
        XCTAssertEqual(swiftDevice.batteryLevel, objcDevice.batteryLevel?.doubleValue)
        XCTAssertEqual(swiftDevice.brand, objcDevice.brand)
        XCTAssertEqual(swiftDevice.brightnessLevel, objcDevice.brightnessLevel?.doubleValue)
        XCTAssertEqual(swiftDevice.isLowRam, objcDevice.isLowRam?.boolValue)
        XCTAssertEqual(swiftDevice.locale, objcDevice.locale)
        XCTAssertEqual(swiftDevice.locales, objcDevice.locales)
        XCTAssertEqual(swiftDevice.logicalCpuCount, objcDevice.logicalCpuCount?.doubleValue)
        XCTAssertEqual(swiftDevice.model, objcDevice.model)
        XCTAssertEqual(swiftDevice.name, objcDevice.name)
        XCTAssertEqual(swiftDevice.powerSavingMode, objcDevice.powerSavingMode?.boolValue)
        XCTAssertEqual(swiftDevice.timeZone, objcDevice.timeZone)
        XCTAssertEqual(swiftDevice.totalRam, objcDevice.totalRam?.doubleValue)
        XCTAssertEqual(swiftDevice.type, objcDevice.type.toSwift)
    }
}
