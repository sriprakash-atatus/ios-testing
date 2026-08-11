/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`, `ddTrace` -> `AtatusTrace`; renamed `dd*` types to `Atatus*`; renamed `dd*`
// members to `at*`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusTrace
@testable import AtatusCore

@MainActor
class ActiveSpansPoolTests: XCTestCase, Sendable {
    private var core: AtatusCoreProtocol! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() async throws {
        core = PassthroughCoreMock()
    }

    override func tearDown() async throws {
        core = nil
    }

    func testsWhenSpanIsStartedIsAssignedToActiveSpan() throws {
        let tracer = AtatusTracer.mockAny(in: core)
        let previousSpan = tracer.activeSpan
        XCTAssertNil(previousSpan)

        let oneSpan = tracer.startSpan(operationName: .mockAny()).setActive()
        XCTAssert(tracer.activeSpan?.dd.atContext.spanID == oneSpan.dd.atContext.spanID)
        oneSpan.finish()
        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    func testsWhenSpanIsFinishedIsRemovedFromActiveSpan() throws {
        let tracer = AtatusTracer.mockAny(in: core)
        XCTAssertNil(tracer.activeSpan)

        let oneSpan = tracer.startSpan(operationName: .mockAny()).setActive()
        XCTAssert(tracer.activeSpan?.dd.atContext.spanID == oneSpan.dd.atContext.spanID)

        oneSpan.finish()
        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    func testsSpanWithoutParentInheritsActiveSpan() throws {
        let tracer = AtatusTracer.mockAny(in: core)
        let firstSpan = tracer.startSpan(operationName: .mockAny())
        firstSpan.setActive()
        let previousActiveSpan = tracer.activeSpan
        let secondSpan = tracer.startSpan(operationName: .mockAny())
        secondSpan.setActive()
        XCTAssertEqual(secondSpan.dd.atContext.parentSpanID, previousActiveSpan?.dd.atContext.spanID)
        XCTAssertEqual(secondSpan.dd.atContext.spanID,  tracer.activeSpan?.dd.atContext.spanID)
        XCTAssertEqual(secondSpan.dd.atContext.parentSpanID, firstSpan.dd.atContext.spanID)

        secondSpan.finish()
        XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, firstSpan.dd.atContext.spanID)
        firstSpan.finish()
        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    func testsSpanWithParentDoesntInheritActiveSpan() throws {
        let tracer = AtatusTracer.mockAny(in: core)
        let oneSpan = tracer.startSpan(operationName: .mockAny())
        let otherSpan = tracer.startSpan(operationName: .mockAny()).setActive()

        let spanWithParent = tracer.startSpan(operationName: .mockAny(), childOf: oneSpan.context)

        XCTAssertEqual(spanWithParent.dd.atContext.parentSpanID, oneSpan.dd.atContext.spanID)
        spanWithParent.finish()
        XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, otherSpan.dd.atContext.spanID)
        oneSpan.finish()
        otherSpan.finish()
        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    @available(iOS 13.0, tvOS 13, *)
    func testActiveSpanIsKeptPerTask() async throws {
        let tracer = AtatusTracer.mockAny(in: core)
        let oneSpan = tracer.startSpan(operationName: .mockAny()).setActive()

        let task1 = Task {
            let firstSpan = tracer.startSpan(operationName: .mockAny()).setActive()
            XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, firstSpan.dd.atContext.spanID)
            return firstSpan
        }

        let task2 = Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, oneSpan.dd.atContext.spanID)
            let secondSpan = tracer.startSpan(operationName: .mockAny()).setActive()
            XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, secondSpan.dd.atContext.spanID)
            return secondSpan
        }

        let (firstSpan, secondSpan) = try await (task1.value, task2.value)
        XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, oneSpan.dd.atContext.spanID)
        oneSpan.finish()
        firstSpan.finish()
        secondSpan.finish()

        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    func testSetActiveSpanCalledMultipleTimesInSingleSpan() throws {
        let tracer = AtatusTracer.mockAny(in: core)
        defer { tracer.activeSpansPool.destroy() }

        let span = tracer.startSpan(operationName: "Reactivated")
        (3...Int.mockRandom(min: 3, max: 10)).forEach { _ in
            span.setActive()
        }

        XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, span.dd.atContext.spanID)

        span.finish()

        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    func testSetActiveSpanCalledMultipleTimesInTwoSpans() throws {
        let tracer = AtatusTracer.mockAny(in: core)
        defer { tracer.activeSpansPool.destroy() }

        let firstSpan = tracer.startSpan(operationName: .mockAny()).setActive()
        firstSpan.setActive()

        let previousActiveSpan = tracer.activeSpan

        let secondSpan = tracer.startSpan(operationName: .mockAny()).setActive()
        firstSpan.setActive()
        secondSpan.setActive()

        XCTAssertEqual(secondSpan.dd.atContext.parentSpanID, previousActiveSpan?.dd.atContext.spanID)
        XCTAssertEqual(secondSpan.dd.atContext.spanID,  tracer.activeSpan?.dd.atContext.spanID)
        XCTAssertEqual(secondSpan.dd.atContext.parentSpanID, firstSpan.dd.atContext.spanID)

        secondSpan.finish()
        XCTAssertEqual(tracer.activeSpan?.dd.atContext.spanID, firstSpan.dd.atContext.spanID)
        firstSpan.finish()
        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    func testSetActive_givenParentWithMultipleChildren() throws {
        let tracer = AtatusTracer.mockAny(in: core)
        defer { tracer.activeSpansPool.destroy() }

        let parentSpan = tracer.startSpan(operationName: .mockAny()).setActive()
        let child1Span = tracer.startSpan(operationName: "Child1").setActive()
        child1Span.finish()

        let child2Span = tracer.startSpan(operationName: "Child2")
        child2Span.finish()
        parentSpan.finish()

        XCTAssertEqual(child1Span.dd.atContext.traceID, parentSpan.dd.atContext.traceID)
        XCTAssertEqual(child1Span.dd.atContext.parentSpanID, parentSpan.dd.atContext.spanID)
        XCTAssertEqual(child2Span.dd.atContext.traceID, parentSpan.dd.atContext.traceID)
        XCTAssertEqual(child2Span.dd.atContext.parentSpanID, parentSpan.dd.atContext.spanID)

        XCTAssertNil(tracer.activeSpan)
        XCTAssertTrue(tracer.activeSpansPool.isEmpty)
    }

    func testSetActive_activeSpanProviderWorks() throws {
        let core = AtatusCoreProxy()
        Trace.enable(in: core)
        let tracer = Tracer.shared(in: core)

        core.scope(for: TraceFeature.self).context { context in
            guard let provider = context.additionalContext(ofType: TraceCoreContext.ActiveSpanProvider.self) else {
                XCTFail("Additional context for ActiveSpanProvider is nil unexpectedly.")
                return
            }

            XCTAssertNil(provider.activeSpanContext())

            let oneSpan = tracer.startSpan(operationName: .mockAny()).setActive()
            XCTAssertEqual(provider.activeSpanContext()?.activeSpanID, oneSpan.dd.atContext.spanID)
            XCTAssertEqual(provider.activeSpanContext()?.traceID, oneSpan.dd.atContext.traceID)

            oneSpan.finish()
            XCTAssertNil(provider.activeSpanContext())
        }
    }
}
