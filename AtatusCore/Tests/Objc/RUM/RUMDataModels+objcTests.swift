/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`, `ddRUM` -> `AtatusRUM`; renamed the `DD` symbol prefix to `AT`; rebranded the
// licence header.

import XCTest
import TestUtilities
import AtatusInternal
@_spi(objc)
@testable import AtatusRUM
@testable import AtatusCore

class RUMDataModels_objcTests: XCTestCase {
    func testGivenObjectiveCViewEventWithAnyAttributes_whenReadingAttributes_theirTypeIsNotAltered() throws {
        let expectedContextAttributes: [String: Any] = mockRandomAttributes()
        let expectedUserInfoAttributes: [String: Any] = mockRandomAttributes()

        // Given
        var swiftView: RUMViewEvent = .mockRandom()
        swiftView.context?.contextInfo = expectedContextAttributes.dd.swiftAttributes
        swiftView.usr?.usrInfo = expectedUserInfoAttributes.dd.swiftAttributes

        let objcView = objc_RUMViewEvent(swiftModel: swiftView)

        // When
        let receivedContextAttributes = try XCTUnwrap(objcView.context?.contextInfo)
        let receivedUserInfoAttributes = try XCTUnwrap(objcView.usr?.usrInfo)

        // Then
        ATAssertDictionariesEqual(receivedContextAttributes, expectedContextAttributes)
        ATAssertDictionariesEqual(receivedUserInfoAttributes, expectedUserInfoAttributes)
    }

    func testGivenObjectiveCResourceEventWithAnyAttributes_whenReadingAttributes_theirTypeIsNotAltered() throws {
        let expectedContextAttributes: [String: Any] = mockRandomAttributes()
        let expectedUserInfoAttributes: [String: Any] = mockRandomAttributes()

        // Given
        var swiftResource: RUMResourceEvent = .mockRandom()
        swiftResource.context?.contextInfo = expectedContextAttributes.dd.swiftAttributes
        swiftResource.usr?.usrInfo = expectedUserInfoAttributes.dd.swiftAttributes

        let objcResource = objc_RUMResourceEvent(swiftModel: swiftResource)

        // When
        let receivedContextAttributes = try XCTUnwrap(objcResource.context?.contextInfo)
        let receivedUserInfoAttributes = try XCTUnwrap(objcResource.usr?.usrInfo)

        // Then
        ATAssertDictionariesEqual(receivedContextAttributes, expectedContextAttributes)
        ATAssertDictionariesEqual(receivedUserInfoAttributes, expectedUserInfoAttributes)
    }

    func testGivenObjectiveCActionEventWithAnyAttributes_whenReadingAttributes_theirTypeIsNotAltered() throws {
        let expectedContextAttributes: [String: Any] = mockRandomAttributes()
        let expectedUserInfoAttributes: [String: Any] = mockRandomAttributes()

        // Given
        var swiftAction: RUMActionEvent = .mockAny()
        swiftAction.context?.contextInfo = expectedContextAttributes.dd.swiftAttributes
        swiftAction.usr?.usrInfo = expectedUserInfoAttributes.dd.swiftAttributes

        let objcAction = objc_RUMActionEvent(swiftModel: swiftAction)

        // When
        let receivedContextAttributes = try XCTUnwrap(objcAction.context?.contextInfo)
        let receivedUserInfoAttributes = try XCTUnwrap(objcAction.usr?.usrInfo)

        // Then
        ATAssertDictionariesEqual(receivedContextAttributes, expectedContextAttributes)
        ATAssertDictionariesEqual(receivedUserInfoAttributes, expectedUserInfoAttributes)
    }

    func testGivenObjectiveCErrorEventWithAnyAttributes_whenReadingAttributes_theirTypeIsNotAltered() throws {
        let expectedContextAttributes: [String: Any] = mockRandomAttributes()
        let expectedUserInfoAttributes: [String: Any] = mockRandomAttributes()

        // Given
        var swiftError: RUMErrorEvent = .mockRandom()
        swiftError.context?.contextInfo = expectedContextAttributes.dd.swiftAttributes
        swiftError.usr?.usrInfo = expectedUserInfoAttributes.dd.swiftAttributes

        let objcError = objc_RUMErrorEvent(swiftModel: swiftError)

        // When
        let receivedContextAttributes = try XCTUnwrap(objcError.context?.contextInfo)
        let receivedUserInfoAttributes = try XCTUnwrap(objcError.usr?.usrInfo)

        // Then
        ATAssertDictionariesEqual(receivedContextAttributes, expectedContextAttributes)
        ATAssertDictionariesEqual(receivedUserInfoAttributes, expectedUserInfoAttributes)
    }

    func testGivenObjectiveCLongTaskEventWithAnyAttributes_whenReadingAttributes_theirTypeIsNotAltered() throws {
        let expectedContextAttributes: [String: Any] = mockRandomAttributes()
        let expectedUserInfoAttributes: [String: Any] = mockRandomAttributes()

        // Given
        var swiftLongTask: RUMLongTaskEvent = .mockRandom()
        swiftLongTask.context?.contextInfo = expectedContextAttributes.dd.swiftAttributes
        swiftLongTask.usr?.usrInfo = expectedUserInfoAttributes.dd.swiftAttributes

        let objcLongTask = objc_RUMLongTaskEvent(swiftModel: swiftLongTask)

        // When
        let receivedContextAttributes = try XCTUnwrap(objcLongTask.context?.contextInfo)
        let receivedUserInfoAttributes = try XCTUnwrap(objcLongTask.usr?.usrInfo)

        // Then
        ATAssertDictionariesEqual(receivedContextAttributes, expectedContextAttributes)
        ATAssertDictionariesEqual(receivedUserInfoAttributes, expectedUserInfoAttributes)
    }
}
