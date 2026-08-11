/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusRUM

class RUMEventsMapperTests: XCTestCase {
    func testGivenMappersEnabled_whenModifyingEvents_itReturnsTheirNewRepresentation() throws {
        let originalViewEvent: RUMViewEvent = .mockRandom()
        let modifiedViewEvent: RUMViewEvent = .mockRandom()

        let originalErrorEvent: RUMErrorEvent = .mockRandom()
        let modifiedErrorEvent: RUMErrorEvent = .mockRandom()

        let originalResourceEvent: RUMResourceEvent = .mockRandom()
        let modifiedResourceEvent: RUMResourceEvent = .mockRandom()

        let originalActionEvent: RUMActionEvent = .mockAny()
        let modifiedActionEvent: RUMActionEvent = .mockAny()

        let originalLongTaskEvent: RUMLongTaskEvent = .mockRandom()
        let modifiedLongTaskEvent: RUMLongTaskEvent = .mockRandom()

        // Given
        let mapper: RUMEventsMapper = .mockWith(
            viewEventMapper: { viewEvent in
                ATAssertReflectionEqual(viewEvent, originalViewEvent, "Mapper should be called with the original event.")
                return modifiedViewEvent
            },
            errorEventMapper: { errorEvent in
                ATAssertReflectionEqual(errorEvent, originalErrorEvent, "Mapper should be called with the original event.")
                return modifiedErrorEvent
            },
            resourceEventMapper: { resourceEvent in
                ATAssertReflectionEqual(resourceEvent, originalResourceEvent, "Mapper should be called with the original event.")
                return modifiedResourceEvent
            },
            actionEventMapper: { actionEvent in
                ATAssertReflectionEqual(actionEvent, originalActionEvent, "Mapper should be called with the original event.")
                return modifiedActionEvent
            },
            longTaskEventMapper: { longTaskEvent in
                ATAssertReflectionEqual(longTaskEvent, originalLongTaskEvent, "Mapper should be called with the original event.")
                return modifiedLongTaskEvent
            }
        )

        // When
        let mappedViewEvent = mapper.map(event: originalViewEvent)
        let mappedErrorEvent = mapper.map(event: originalErrorEvent)
        let mappedResourceEvent = mapper.map(event: originalResourceEvent)
        let mappedActionEvent = mapper.map(event: originalActionEvent)
        let mappedLongTaskEvent = mapper.map(event: originalLongTaskEvent)

        // Then
        ATAssertReflectionEqual(try XCTUnwrap(mappedViewEvent), modifiedViewEvent, "Mapper should return modified event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedErrorEvent), modifiedErrorEvent, "Mapper should return modified event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedResourceEvent), modifiedResourceEvent, "Mapper should return modified event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedActionEvent), modifiedActionEvent, "Mapper should return modified event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedLongTaskEvent), modifiedLongTaskEvent, "Mapper should return modified event.")
    }

    func testGivenMappersEnabled_whenDroppingEvents_itReturnsNil() {
        let originalErrorEvent: RUMErrorEvent = .mockRandom()
        let originalResourceEvent: RUMResourceEvent = .mockRandom()
        let originalActionEvent: RUMActionEvent = .mockAny()
        let originalLongTaskEvent: RUMLongTaskEvent = .mockRandom()

        // Given
        let mapper: RUMEventsMapper = .mockWith(
            errorEventMapper: { errorEvent in
                ATAssertReflectionEqual(errorEvent, originalErrorEvent, "Mapper should be called with the original event.")
                return nil
            },
            resourceEventMapper: { resourceEvent in
                ATAssertReflectionEqual(resourceEvent, originalResourceEvent, "Mapper should be called with the original event.")
                return nil
            },
            actionEventMapper: { actionEvent in
                ATAssertReflectionEqual(actionEvent, originalActionEvent, "Mapper should be called with the original event.")
                return nil
            },
            longTaskEventMapper: { longTaskEvent in
                ATAssertReflectionEqual(longTaskEvent, originalLongTaskEvent, "Mapper should be called with the original event.")
                return nil
            }
        )

        // When
        let mappedErrorEvent = mapper.map(event: originalErrorEvent)
        let mappedResourceEvent = mapper.map(event: originalResourceEvent)
        let mappedActionEvent = mapper.map(event: originalActionEvent)
        let mappedLongTaskEvent = mapper.map(event: originalLongTaskEvent)

        // Then
        XCTAssertNil(mappedErrorEvent, "Mapper should return nil.")
        XCTAssertNil(mappedResourceEvent, "Mapper should return nil.")
        XCTAssertNil(mappedActionEvent, "Mapper should return nil.")
        XCTAssertNil(mappedLongTaskEvent, "Mapper should return nil.")
    }

    func testGivenMappersDisabled_whenMappingEvents_itReturnsTheirOriginalRepresentation() throws {
        let originalViewEvent: RUMViewEvent = .mockRandom()
        let originalErrorEvent: RUMErrorEvent = .mockRandom()
        let originalResourceEvent: RUMResourceEvent = .mockRandom()
        let originalActionEvent: RUMActionEvent = .mockAny()
        let originalLongTaskEvent: RUMLongTaskEvent = .mockRandom()

        // Given
        let mapper: RUMEventsMapper = .mockNoOp()

        // When
        let mappedViewEvent = mapper.map(event: originalViewEvent)
        let mappedErrorEvent = mapper.map(event: originalErrorEvent)
        let mappedResourceEvent = mapper.map(event: originalResourceEvent)
        let mappedActionEvent = mapper.map(event: originalActionEvent)
        let mappedLongTaskEvent = mapper.map(event: originalLongTaskEvent)

        // Then
        ATAssertReflectionEqual(try XCTUnwrap(mappedViewEvent), originalViewEvent, "Mapper should return the original event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedErrorEvent), originalErrorEvent, "Mapper should return the original event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedResourceEvent), originalResourceEvent, "Mapper should return the original event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedActionEvent), originalActionEvent, "Mapper should return the original event.")
        ATAssertReflectionEqual(try XCTUnwrap(mappedLongTaskEvent), originalLongTaskEvent, "Mapper should return the original event.")
    }

    func testGivenUnrecognizedEvent_whenMapping_itReturnsItsOriginalImplementation() throws {
        // Given
        struct UnrecognizedEvent: Encodable {
            let value: String
        }

        let originalEvent = UnrecognizedEvent(value: .mockRandom())

        // When
        let mapper: RUMEventsMapper = .mockNoOp()
        let mappedEvent = try XCTUnwrap(mapper.map(event: originalEvent))

        // Then
        XCTAssertEqual(mappedEvent.value, originalEvent.value)
    }
}
