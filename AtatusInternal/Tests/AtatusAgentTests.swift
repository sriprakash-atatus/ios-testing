/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import XCTest
import TestUtilities
@testable import AtatusInternal

// ATCHG: New test file covering the Atatus-specific changes ported from the Atatus Android agent:
// the single Atatus site and its `serverUrl` override, the `AgentInfo` identity, the `agent`
// payload object, the renamed intake headers and query parameters, and the heartbeat request.

// MARK: - AtatusSite

class AtatusSiteTests: XCTestCase {
    override func tearDown() {
        AtatusSite.serverUrl = nil
        super.tearDown()
    }

    func testItDefinesOnlyTheAtatusSite() {
        XCTAssertEqual(AtatusSite.atatus.rawValue, "atatus")
    }

    func testItUsesTheAtatusIntakeHost() {
        AtatusSite.serverUrl = nil
        XCTAssertEqual(AtatusSite.atatus.endpoint.absoluteString, "https://mo-rx.atatus.com")
    }

    func testServerUrlOverridesTheIntakeHost() {
        AtatusSite.serverUrl = "https://example.ngrok.io"
        XCTAssertEqual(AtatusSite.atatus.endpoint.absoluteString, "https://example.ngrok.io")
    }

    func testInvalidServerUrlFallsBackToTheIntakeHost() {
        AtatusSite.serverUrl = ""
        XCTAssertEqual(AtatusSite.atatus.endpoint.absoluteString, "https://mo-rx.atatus.com")
    }
}

// MARK: - AgentInfo

class AgentInfoTests: XCTestCase {
    private let defaultName = AgentInfo.agentName
    private let defaultVersion = AgentInfo.agentVersion

    override func tearDown() {
        AgentInfo.agentName = defaultName
        AgentInfo.agentVersion = defaultVersion
        super.tearDown()
    }

    func testItIdentifiesTheNativeIOSAgentByDefault() {
        XCTAssertEqual(AgentInfo.agentName, "Atatus iOS Agent")
        XCTAssertEqual(AgentInfo.agentVersion, "1.0.0")
    }

    func testLogSourceIsNativeByDefault() {
        XCTAssertEqual(AgentInfo.logSource, "swift")
    }

    func testLogSourceFollowsTheCrossPlatformAgentName() {
        AgentInfo.agentName = "Atatus Flutter Agent"
        XCTAssertEqual(AgentInfo.logSource, "flutter")

        AgentInfo.agentName = "Atatus React Native Agent"
        XCTAssertEqual(AgentInfo.logSource, "react-native")
    }

    func testItAppendsTheAgentObjectAsASiblingOfTheEventProperties() throws {
        // Given
        struct Event: Encodable {
            let message: String
        }
        AgentInfo.agentName = "Atatus iOS Agent"
        AgentInfo.agentVersion = "2.3.4"

        // When
        let data = try JSONEncoder().encode(Event(message: "hello").withAgentInfo())

        // Then
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["message"] as? String, "hello")
        let agent = try XCTUnwrap(json["agent"] as? [String: Any])
        XCTAssertEqual(agent["name"] as? String, "Atatus iOS Agent")
        XCTAssertEqual(agent["version"] as? String, "2.3.4")
        XCTAssertNil(json["log_source"], "log_source is only added when explicitly requested")
    }

    func testItAppendsLogSourceWhenRequested() throws {
        // Given
        struct Event: Encodable {
            let message: String
        }

        // When
        let data = try JSONEncoder().encode(Event(message: "hello").withAgentInfo(logSource: "swift"))

        // Then
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["log_source"] as? String, "swift")
    }
}

// MARK: - URLRequestBuilder

class AtatusURLRequestBuilderTests: XCTestCase {
    func testItUsesTheAtatusIntakeHeaderNames() {
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atAPIKeyHeaderField, "api-key")
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atClientTokenHeaderField, "atatus-client-token")
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atEVPOriginHeaderField, "ATATUS-EVP-ORIGIN")
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atEVPOriginVersionHeaderField, "ATATUS-EVP-ORIGIN-VERSION")
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atRequestIDHeaderField, "ATATUS-REQUEST-ID")
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atIdempotencyKeyHeaderField, "AT-IDEMPOTENCY-KEY")
    }

    func testItDefinesTheAgentIdentificationHeaders() {
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atatusAgentNameHeaderField, "ATATUS-AGENT-NAME")
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atatusAgentVersionHeaderField, "ATATUS-AGENT-VERSION")
        XCTAssertEqual(URLRequestBuilder.HTTPHeader.atatusAppNameHeaderField, "ATATUS-APP-NAME")
    }

    func testItEncodesTheAtatusQueryParameterNames() throws {
        // Given
        let builder = URLRequestBuilder(
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://mo-rx.atatus.com/v1/ios/rum")!,
            queryItems: [
                .atatusSource(source: "ios"),
                .atatusTags(tags: ["retry_count:1"]),
                .licenseKey(licenseKey: "license-abc"),
                .agentName(agentName: "Atatus iOS Agent"),
                .agentVersion(agentVersion: "1.0.0"),
                .appName(appName: "MyApp")
            ],
            headers: []
        )

        // When
        let request = builder.uploadRequest(with: Data(), compress: false)

        // Then
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        let query = (components.queryItems ?? []).reduce(into: [String: String]()) { $0[$1.name] = $1.value }
        XCTAssertEqual(query["atatus_source"], "ios")
        XCTAssertEqual(query["atatustags"], "retry_count:1")
        XCTAssertEqual(query["license_key"], "license-abc")
        XCTAssertEqual(query["agent_name"], "Atatus iOS Agent")
        XCTAssertEqual(query["agent_version"], "1.0.0")
        XCTAssertEqual(query["app_name"], "MyApp")
        XCTAssertNil(query["ddsource"])
        XCTAssertNil(query["ddtags"])
    }
}

// MARK: - Heartbeat

class AgentHeartbeatTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private let endpoint = URL(string: "https://mo-rx.atatus.com")!

    private func configuration(licenseKey: String = "license-abc") -> HeartbeatConfiguration {
        HeartbeatConfiguration(
            endpoint: endpoint,
            licenseKey: licenseKey,
            appName: "MyApp",
            source: "ios"
        )
    }

    func testItBuildsTheAgentHeartbeatURL() throws {
        // When
        let url = try XCTUnwrap(
            AgentHeartbeat.heartbeatURL(path: AgentHeartbeat.agentHeartbeatPath, configuration: configuration())
        )

        // Then
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/v1/ios/agent-heartbeat")
        let query = (components.queryItems ?? []).reduce(into: [String: String]()) { $0[$1.name] = $1.value }
        XCTAssertEqual(query["atatus_source"], "ios")
        XCTAssertEqual(query["license_key"], "license-abc")
        XCTAssertEqual(query["agent_name"], AgentInfo.agentName)
        XCTAssertEqual(query["agent_version"], AgentInfo.agentVersion)
        XCTAssertEqual(query["app_name"], "MyApp")
    }

    func testItBuildsTheLogsHeartbeatURL() throws {
        // When
        let url = try XCTUnwrap(
            AgentHeartbeat.heartbeatURL(path: AgentHeartbeat.logsHeartbeatPath, configuration: configuration())
        )

        // Then
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.path, "/v1/ios/log/heart-beat")
    }

    func testItSkipsTheHeartbeatWhenTheLicenseKeyIsBlank() {
        // Given
        let completed = expectation(description: "completed")
        var capturedResult: Bool?

        // When
        AgentHeartbeat.check(
            path: AgentHeartbeat.agentHeartbeatPath,
            configuration: configuration(licenseKey: "")
        ) { allowed in
            capturedResult = allowed
            completed.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertEqual(capturedResult, false, "A blank license key must not produce a request")
    }

    func testLogsAreHeldBackUntilTheFirstHeartbeatAllowsThem() {
        // The Android agent defaults `LogsHeartbeatScheduler.isLogsAllowed` to `false`, so log
        // batches are skipped until the backend answers `allowAgent: true`.
        XCTAssertFalse(LogsHeartbeatScheduler.isLogsAllowed)
    }
}
// ATCHG: End
