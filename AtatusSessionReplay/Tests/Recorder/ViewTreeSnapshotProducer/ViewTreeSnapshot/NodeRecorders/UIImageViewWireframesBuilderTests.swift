/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)
import XCTest
@_spi(Internal)
import TestUtilities
@_spi(Internal)
@testable import AtatusSessionReplay

class UIImageViewWireframesBuilderTests: XCTestCase {
    var wireframesBuilder: WireframesBuilder = .init()

    override func setUp() {
        super.setUp()
        wireframesBuilder = WireframesBuilder()
    }

    func test_BuildCorrectWireframes_fromValidData() {
        let wireframeID = WireframeID.mockRandom()
        let imageWireframeID = WireframeID.mockRandom()
        let builder = UIImageViewWireframesBuilder(
            wireframeID: wireframeID,
            imageWireframeID: imageWireframeID,
            attributes: ViewAttributes.mock(fixture: .visible(.someAppearance)),
            contentFrame: CGRect(x: 10, y: 10, width: 200, height: 200),
            imageResource: .mockRandom(),
            imagePrivacyLevel: .maskNonBundledOnly
        )

        let wireframes = builder.buildWireframes(with: wireframesBuilder)

        XCTAssertEqual(wireframes.count, 2)

        if case let .shapeWireframe(shapeWireframe) = wireframes[0] {
            XCTAssertEqual(shapeWireframe.id, wireframeID)
        } else {
            XCTFail("First wireframe needs to be shapeWireframe case")
        }

        if case let .imageWireframe(imageWireframe) = wireframes[1] {
            XCTAssertEqual(imageWireframe.id, imageWireframeID)
            XCTAssertNil(imageWireframe.base64) // deprecated field
        } else {
            XCTFail("Second wireframe needs to be imageWireframe case")
        }
    }

    func test_BuildCorrectWireframes_whenContentImageIsIgnored() {
        let wireframeID = WireframeID.mockRandom()
        let placeholderWireframeID = WireframeID.mockRandom()
        let builder = UIImageViewWireframesBuilder(
            wireframeID: wireframeID,
            imageWireframeID: placeholderWireframeID,
            attributes: ViewAttributes.mock(fixture: .visible(.someAppearance)),
            contentFrame: CGRect(x: 10, y: 10, width: 200, height: 200),
            imageResource: nil,
            imagePrivacyLevel: .maskNonBundledOnly
        )

        let wireframes = builder.buildWireframes(with: wireframesBuilder)

        XCTAssertEqual(wireframes.count, 2)

        if case let .shapeWireframe(shapeWireframe) = wireframes[0] {
            XCTAssertEqual(shapeWireframe.id, wireframeID)
        } else {
            XCTFail("First wireframe needs to be shapeWireframe case")
        }

        if case let .placeholderWireframe(placeholderWireframe) = wireframes[1] {
            XCTAssertEqual(placeholderWireframe.id, placeholderWireframeID)
            XCTAssertEqual(placeholderWireframe.label, "Content Image")
        } else {
            XCTFail("Second wireframe needs to be imageWireframe case")
        }
    }
}
#endif
