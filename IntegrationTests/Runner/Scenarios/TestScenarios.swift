/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusCore
import AtatusLogs
import AtatusRUM
import AtatusTrace
import AtatusSessionReplay

protocol TestScenario: AnyObject {
    /// The name of the storyboard containing this scenario.
    static var storyboardName: String { get }

    /// The value of initial tracking consent for this scenario.
    /// Defaults to `.granted`
    var initialTrackingConsent: TrackingConsent { get }

    /// Applies additional SDK configuration for running this scenario.
    /// Defaults to no-op.
    func override(configuration: inout Atatus.Configuration)

    /// Applies additional Feature configuration for running this scenario.
    /// Defaults to no-op.
    func configureFeatures()

    init()
}

/// Defaults.
extension TestScenario {
    var initialTrackingConsent: TrackingConsent { .granted }
    func override(configuration: inout Atatus.Configuration) { /* no-op */ }
    func configureFeatures() { /* no-op */ }
}

internal func initializeTestScenario(with className: String) -> TestScenario {
    let canonicalClassName = "Runner.\(className)"
    let scenarioClass = NSClassFromString(canonicalClassName) as? TestScenario.Type

    guard let scenario = scenarioClass?.init() else {
        fatalError("Cannot initialize `TestScenario` with class name: \(className)")
    }

    return scenario
}

// MARK: - Atatus Demo

// ATCHG: Scenario used by `.github/workflows/ios-agent-test.yml` to exercise the whole agent —
// RUM, Logs and Traces — against a real Atatus intake.
//
// No feature sets a `customEndpoint` here on purpose: that makes every intake request fall back to
// `AtatusSite.serverUrl`, which the agent already reads from the `ATATUS_SERVER_URL` environment
// variable. Credentials come from the environment for the same reason, so nothing is committed.
//
// Everything is generated from code rather than from taps, so a plain `simctl launch` produces the
// full set of signals without a test runner driving the UI.
final class AtatusDemoScenario: TestScenario {
    /// Reuses the manual RUM storyboard, so the app shows a real screen and its first RUM view is
    /// started by `SendRUMFixture1ViewController`, exactly as in the RUM integration tests.
    static let storyboardName = "RUMManualInstrumentationScenario"

    /// Retained for the lifetime of the traced request.
    private var session: URLSession?

    func configureFeatures() {
        var tracedHosts: Set<String> = []
        if let host = Environment.tracedRequestURL()?.host {
            tracedHosts.insert(host)
        }

        var rum = RUM.Configuration(applicationID: Environment.rumApplicationID())
        rum.telemetrySampleRate = 100
        if !tracedHosts.isEmpty {
            rum.urlSessionTracking = .init(
                firstPartyHostsTracing: .trace(hosts: tracedHosts, sampleRate: 100)
            )
        }
        RUM.enable(with: rum)

        Logs.enable(with: Logs.Configuration())

        var trace = Trace.Configuration(sampleRate: 100)
        trace.networkInfoEnabled = true
        trace.tags = ["test.suite": "ios-agent-test"]
        if !tracedHosts.isEmpty {
            trace.urlSessionTracking = .init(
                firstPartyHostsTracing: .trace(hosts: tracedHosts, sampleRate: 100)
            )
        }
        Trace.enable(with: trace)

        // Session Replay records the screen and rides on the RUM session, so it has to be enabled
        // after RUM. Masking is dialled down to the least the SDK allows so the recording is
        // actually readable in a replay viewer: only sensitive inputs are masked, images are shown,
        // and touches are drawn.
        var replay = SessionReplay.Configuration(replaySampleRate: 100)
        replay.textAndInputPrivacyLevel = .maskSensitiveInputs
        replay.imagePrivacyLevel = .maskNone
        replay.touchPrivacyLevel = .show
        SessionReplay.enable(with: replay)

        // Let the first RUM view start before layering the rest on top of it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.generateTelemetry()
        }
    }

    private func generateTelemetry() {
        sendLogs()
        sendSpans()
        sendRUMEvents()
        sendTracedRequest()
    }

    private func sendLogs() {
        logger?.addAttribute(forKey: "test.suite", value: "ios-agent-test")
        logger?.debug("demo debug message", attributes: ["log.level": "debug"])
        logger?.info("demo info message", attributes: ["log.level": "info"])
        logger?.notice("demo notice message", attributes: ["log.level": "notice"])
        logger?.warn("demo warn message", attributes: ["log.level": "warn"])
        logger?.error("demo error message", attributes: ["log.level": "error"])
        logger?.critical("demo critical message", attributes: ["log.level": "critical"])
        logger?.error(
            "demo error message with attached error",
            error: DemoError.simulated,
            attributes: ["log.level": "error"]
        )
    }

    private func sendSpans() {
        let tracer = Tracer.shared()

        let rootSpan = tracer.startRootSpan(operationName: "demo.scenario").setActive()
        rootSpan.setTag(key: "test.suite", value: "ios-agent-test")
        rootSpan.setBaggageItem(key: "scenario", value: "AtatusDemoScenario")

        let childSpan = tracer.startSpan(operationName: "demo.child.work")
        childSpan.setTag(key: "work.kind", value: "compute")
        childSpan.log(fields: [OTLogFields.message: "child span progress", "progress": 1.0])
        childSpan.finish()

        let failingSpan = tracer.startSpan(operationName: "demo.child.failure")
        failingSpan.setTag(key: OTTags.error, value: true)
        failingSpan.setError(DemoError.simulated)
        failingSpan.finish()

        rootSpan.finish()
    }

    private func sendRUMEvents() {
        rumMonitor.addAttribute(forKey: "test.suite", value: "ios-agent-test")
        rumMonitor.addTiming(name: "demo-content-ready")
        rumMonitor.addAction(type: .custom, name: "demo custom action", attributes: ["action.origin": "ci"])

        let resourceKey = "/demo/resource"
        let resourceRequest = URLRequest(url: URL(string: "https://api.example.com/demo/resource")!)
        rumMonitor.startResource(resourceKey: resourceKey, request: resourceRequest)
        rumMonitor.stopResourceWithError(
            resourceKey: resourceKey,
            error: DemoError.simulated,
            response: HTTPURLResponse(url: resourceRequest.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!,
            attributes: [:]
        )

        rumMonitor.addError(message: "demo RUM error", source: .source)
    }

    /// Issues one real request to the configured first party URL, so the agent produces a network
    /// span and injects its trace propagation headers into a request a backend can pick up.
    private func sendTracedRequest() {
        guard let url = Environment.tracedRequestURL() else {
            return
        }

        URLSessionInstrumentation.enableDurationBreakdown(with: .init(delegateClass: CustomURLSessionDelegate.self))
        let session = URLSession(configuration: .ephemeral, delegate: CustomURLSessionDelegate(), delegateQueue: nil)
        self.session = session

        session.dataTask(with: url) { _, response, error in
            let status = (response as? HTTPURLResponse).map { "\($0.statusCode)" } ?? "no response"
            print("⭐️ [AtatusDemoScenario] traced request to \(url) finished: \(status), error: \(String(describing: error))")
        }
        .resume()
    }
}

/// A distinct error type, so the errors this scenario reports are recognisable in the intake.
private enum DemoError: Error {
    case simulated
}
