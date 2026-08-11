/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusRUM

final class DeviceInfoTests: XCTestCase {
    func testItSetsProperties() {
        let randomModel: String = .mockRandom()
        let randomName: String = .mockRandom()
        let randomArch: String = .mockRandom()
        let batteryLevel: Double = .mockRandom()
        let brightnessLevel: Double = .mockRandom()
        let powerSavingMode: Bool = .mockRandom()
        let locale: String = "en"
        let logicalCpuCount: Double = .mockRandom()
        let totalRam: Double = .mockRandom()

        let info: Device = .mockWith(
            architecture: randomArch,
            batteryLevel: batteryLevel,
            brightnessLevel: brightnessLevel,
            locale: locale,
            model: randomModel,
            name: randomName,
            powerSavingMode: powerSavingMode,
            logicalCpuCount: logicalCpuCount,
            totalRam: totalRam
        )

        XCTAssertEqual(info.brand, "Apple")
        XCTAssertEqual(info.name, randomName)
        XCTAssertEqual(info.model, randomModel)
        XCTAssertEqual(info.architecture, randomArch)
        XCTAssertEqual(info.batteryLevel, batteryLevel)
        XCTAssertEqual(info.brightnessLevel, brightnessLevel)
        XCTAssertEqual(info.locale, locale)
        XCTAssertEqual(info.powerSavingMode, powerSavingMode)
        XCTAssertEqual(info.logicalCpuCount, logicalCpuCount)
        XCTAssertEqual(info.totalRam, totalRam)
    }

    func testItInfersDeviceTypeFromDeviceModel() {
        let iPhone: DeviceInfo = .mockWith(model: "iPhone" + String.mockRandom(among: .alphanumerics, length: 2))
        let iPod: DeviceInfo = .mockWith(model: "iPod" + String.mockRandom(among: .alphanumerics, length: 2))
        let iPad: DeviceInfo = .mockWith(model: "iPad" + String.mockRandom(among: .alphanumerics, length: 2))
        let appleTV: DeviceInfo = .mockWith(model: "AppleTV" + String.mockRandom(among: .alphanumerics, length: 2))
        let unknownDevice: DeviceInfo = .mockWith(model: .mockRandom())

        XCTAssertEqual(iPhone.type.normalizedDeviceType, .mobile)
        XCTAssertEqual(iPod.type.normalizedDeviceType, .mobile)
        XCTAssertEqual(iPad.type.normalizedDeviceType, .tablet)
        XCTAssertEqual(appleTV.type.normalizedDeviceType, .tv)
        XCTAssertEqual(unknownDevice.type.normalizedDeviceType, .other)
    }
}
