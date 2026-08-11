/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddTrace` -> `AtatusTrace`; renamed the `DD`
// symbol prefix to `AT`; rebranded the licence header.

import XCTest
@testable import AtatusTrace

class ATSpanContextTests: XCTestCase {
    func testIteratingOverBaggageItems() {
        let baggageItems = BaggageItems(parent: nil)
        baggageItems.set(key: "k1", value: "v1")
        baggageItems.set(key: "k2", value: "v2")
        baggageItems.set(key: "k3", value: "v3")
        baggageItems.set(key: "k4", value: "v4")

        let context: ATSpanContext = .mockWith(baggageItems: baggageItems)

        var allItems: [String: String] = [:]
        var someItems: [String: String] = [:]

        context.forEachBaggageItem { itemKey, itemValue -> Bool in
            allItems[itemKey] = itemValue
            return false // never stop the iteration
        }
        context.forEachBaggageItem { itemKey, itemValue -> Bool in
            someItems[itemKey] = itemValue
            return itemKey == "k2" || itemKey == "k3" // stop the iteration at `k2` or `k3`, whichever comes first
        }

        let expectedAllItems = ["k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"]
        XCTAssertEqual(allItems, expectedAllItems)
        XCTAssertLessThan(someItems.count, expectedAllItems.count)
        XCTAssertTrue(Set(someItems.keys).isSubset(of: expectedAllItems.keys))
    }

    func testChildItemsOverwriteTheParentItems() {
        let parentBaggageItems = BaggageItems(parent: nil)
        let childBaggageItems = BaggageItems(parent: parentBaggageItems)

        parentBaggageItems.set(key: "foo", value: "a")
        XCTAssertEqual(parentBaggageItems.all["foo"], "a")
        XCTAssertEqual(childBaggageItems.all["foo"], "a")

        childBaggageItems.set(key: "foo", value: "b")
        XCTAssertEqual(parentBaggageItems.all["foo"], "a")
        XCTAssertEqual(childBaggageItems.all["foo"], "b")
    }

    func testChildItemsGetParentItems() {
        let parentBaggageItems = BaggageItems(parent: nil)
        let childBaggageItems = BaggageItems(parent: parentBaggageItems)

        parentBaggageItems.set(key: "foo", value: "a")
        childBaggageItems.set(key: "bar", value: "b")

        XCTAssertEqual(childBaggageItems.get(key: "foo"), "a")

        XCTAssertNil(parentBaggageItems.get(key: "bar"))
        XCTAssertEqual(childBaggageItems.get(key: "bar"), "b")
    }
}
