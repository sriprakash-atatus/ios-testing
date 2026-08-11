/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`;
// rebranded the licence header.

import XCTest
import TestUtilities
@testable import AtatusInternal
@testable import AtatusCore

/// Observes unit tests execution and performs integrity checks after each test to ensure that the global state is unaltered.
@objc
internal class AtatusTestsObserver: NSObject, XCTestObservation {
    @objc
    static func startObserving() {
        let observer = AtatusTestsObserver()
        XCTestObservationCenter.shared.addTestObserver(observer)
    }

    // MARK: - Checking Tests Integrity

    /// A list of checks ensuring global state integrity before and after each tests.
    private let checks: [TestIntegrityCheck] = [
        .init(
            assert: { CoreRegistry.instances.isEmpty },
            problem: "No instance of `AtatusCore` must be left initialized after test completion.",
            solution: """
            Make sure deinitialization APIs are called before the end of test that registers `AtatusCore`.
            If registering directly to `CoreRegistry`, make sure the test cleans it up properly.

            `AtatusTestsObserver` found following instances still being registered: \(CoreRegistry.instances.map({ "'\($0.key)'" }))
            """
        ),
        .init(
            assert: { Swizzling.methods.isEmpty },
            problem: "No swizzling must be applied.",
            solution: """
            Make sure all applied swizzling are reset by the end of test with `unswizzle()`.

            `AtatusTestsObserver` found \(Swizzling.methods.count) leaked swizzlings:
            \(Swizzling.description)
            """
        ),
        .init(
            assert: { AT.logger is InternalLogger },
            problem: "`AT.logger` must use `InternalLogger` implementation.",
            solution: """
            Make sure the `AT` bundle is reset after test to use previous dependencies, e.g.:

            ```
            let dd = AT.mockWith(logger: CoreLoggerMock())
            defer { dd.reset() }
            ```
            """
        ),
        .init(
            assert: { ServerMock.activeInstance == nil },
            problem: "`ServerMock` must not be active.",
            solution: """
            Make sure that test waits for `ServerMock` completion at the end:

            ```
            let server = ServerMock(...)

            // ... testing

            server.wait<...>(...) // <-- after return, no reference to `server` will exist as it processed all callbacks and got be safely deallocated
            ```
            """
        ),
        .init(
            assert: { !FileManager.default.fileExists(atPath: temporaryDirectory.path) },
            problem: "`temporaryDirectory` must not exist.",
            solution: """
            Make sure `DeleteTemporaryDirectory()` is called consistently
            with `CreateTemporaryDirectory()`.
            """
        ),
        .init(
            assert: { !temporaryCoreDirectory.coreDirectory.exists()
                && !temporaryCoreDirectory.osDirectory.exists()
            },
            problem: "`temporaryCoreDirectory` must not exist.",
            solution: """
            Make sure `temporaryCoreDirectory.delete()` is called consistently
            with `temporaryCoreDirectory.create()`.
            """
        ),
        .init(
            assert: {
                !temporaryFeatureDirectories.authorized.exists()
                    && !temporaryFeatureDirectories.unauthorized.exists()
            },
            problem: "`temporaryFeatureDirectories` must not exist.",
            solution: """
            Make sure that `temporaryFeatureDirectories` is unifromly managed in every test by using:
            ```
            // Before test:
            temporaryFeatureDirectories.create()

            // After test:
            temporaryFeatureDirectories.delete()
            ```
            """
        ),
        .init(
            assert: { AtatusCoreProxy.referenceCount == 0 },
            problem: "Leaking reference to `AtatusCoreProtocol`",
            solution: """
            There should be no remaining reference to `AtatusCoreProtocol` upon each test completion
            but some instances of `AtatusCoreProxy` are still alive.

            Make sure the instance of `AtatusCoreProxy` is properly managed in test:
            - it must be allocated on each test start (e.g. in `setUp()` or directly in test)
            - it must be flushed and deinitialized before test ends with `.flushAndTearDown()`
            - it must be deallocated before test ends (e.g. in `tearDown()`)

            If all above conditions are met, this failure might indicate a memory leak in the implementation.
            """
        ),
        .init(
            assert: { PassthroughCoreMock.referenceCount == 0 },
            problem: "Leaking reference to `AtatusCoreProtocol`",
            solution: """
            There should be no remaining reference to `AtatusCoreProtocol` upon each test completion
            but some instances of `PassthroughCoreMock` are still alive.

            Make sure the instance of `PassthroughCoreMock` is properly managed in test:
            - it must be allocated on each test test start (e.g. in `setUp()` or directly in test)
            - it must be deallocated before test ends (e.g. in `tearDown()`)

            If all above conditions are met, this failure might indicate a memory leak in the implementation.
            """
        )
    ]

    func testCaseDidFinish(_ testCase: XCTestCase) {
        if testCase.testRun?.hasSucceeded == true {
            performIntegrityChecks(after: testCase)
        }
    }

    private func performIntegrityChecks(after testCase: XCTestCase) {
        let failedChecks = checks.filter { $0.assert() == false }

        if !failedChecks.isEmpty {
            var message = """
            🐶✋ `AtatusTests` integrity check failure.

            `AtatusTestsObserver` found that `\(testCase.name)` breaks \(failedChecks.count) integrity rule(s) which
            must be fulfilled before and after each unit test. Find potential root cause analysis below and try running
            surrounding tests in isolation to pinpoint the issue:
            """
            failedChecks.forEach { check in
                message += """
                \n⚠️ ---- \(check.problem) ----
                🔎 \(check.solution())
                """
            }

            message += "\n"
            preconditionFailure(message)
        }
    }
}

private struct TestIntegrityCheck {
    /// If this assertion evaluates to `false`, the integrity issue is raised.
    let assert: () -> Bool
    /// What is the assertion about?
    let problem: StaticString
    /// How to fix it if it fails?
    let solution: () -> String

    init(assert: @escaping () -> Bool, problem: StaticString, solution: @escaping @autoclosure () -> String) {
        self.assert = assert
        self.problem = problem
        self.solution = solution
    }
}
