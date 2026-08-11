/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`, `ddWebViewTracking` -> `AtatusWebViewTracking`; renamed `dd*` types to
// `Atatus*`; renamed the `_dd` attribute prefix to `_atatus`; renamed the `ddsource` / `ddtags` query
// parameters to `atatus_source` / `atatustags`; rebranded the licence header.

import XCTest

#if !os(tvOS) && !os(watchOS)

import AtatusInternal
import TestUtilities
import WebKit

@testable import AtatusRUM
@testable import AtatusWebViewTracking

@MainActor
class WebEventIntegrationTests: XCTestCase {
    private var core: AtatusCoreProxy! // swiftlint:disable:this implicitly_unwrapped_optional
    private var controller: WKUserContentControllerMock! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUpWithError() throws {
        core = AtatusCoreProxy(
            context: .mockWith(
                env: "test",
                version: "1.1.1",
                serverTimeOffset: 123
            )
        )

        let config = WKWebViewConfiguration()
        controller = WKUserContentControllerMock()
        config.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: config)

        try WebViewTracking.enableOrThrow(
            tracking: webView,
            hosts: [],
            hostsSanitizer: HostsSanitizer(),
            logsSampleRate: 100,
            in: core
        )
    }

    override func tearDownWithError() throws {
        try core.flushAndTearDown()
        core = nil
        controller = nil
    }

    func testWebEventIntegration() throws {
        // Given
        let randomApplicationID: String = .mockRandom()
        let randomUUID: RUMUUID = .mockRandom()

        RUM.enable(with: .mockWith(applicationID: randomApplicationID) {
            $0.uuidGenerator = RUMUUIDGeneratorMock(uuid: randomUUID)
        }, in: core)

        // Flush to ensure the AnonymousIdentifierManager has generated
        // and propagated the anonymous ID to the context
        core.flush()

        let body = """
        {
          "eventType": "view",
          "event": {
            "application": {
              "id": "xxx"
            },
            "date": \(1_635_932_927_012),
            "service": "super",
            "session": {
              "id": "0110cab4-7471-480e-aa4e-7ce039ced355",
              "type": "user",
              "has_replay": true
            },
            "type": "view",
            "view": {
              "action": {
                "count": 0
              },
              "cumulative_layout_shift": 0,
              "dom_complete": 152800000,
              "dom_content_loaded": 118300000,
              "dom_interactive": 116400000,
              "error": {
                "count": 0
              },
              "first_contentful_paint": 121300000,
              "id": "64308fd4-83f9-48cb-b3e1-1e91f6721230",
              "in_foreground_periods": [],
              "is_active": true,
              "largest_contentful_paint": 121299000,
              "load_event": 152800000,
              "loading_time": 152800000,
              "loading_type": "initial_load",
              "long_task": {
                "count": 0
              },
              "referrer": "",
              "resource": {
                "count": 3
              },
              "time_spent": 3120000000,
              "url": "http://localhost:8080/test.html",
            },
            "_atatus": {
              "document_version": 2,
              "drift": 0,
              "format_version": 2,
              "replay_stats": {
                  "records_count": 10,
                  "segments_count": 1,
                  "segments_total_raw_size": 10
              }
            }
          },
          "tags": [
            "browser_sdk_version:3.6.13"
          ]
        }
        """

        // When
        RUMMonitor.shared(in: core).startView(key: "web-view")
        controller.send(body: body)
        controller.flush()

        // Then
        let expectedUUID = randomUUID.toRUMDataFormat
        let rumMatcher = try XCTUnwrap(core.waitAndReturnRUMEventMatchers().last)
        try rumMatcher.assertItFullyMatches(
            jsonString: """
        {
            "application": {
              "id": "\(randomApplicationID)"
            },
            "date": \(1_635_932_927_012 + 123.dd.toInt64Milliseconds),
            "service": "super",
            "session": {
              "id": "\(expectedUUID)",
              "type": "user"
            },
            "type": "view",
            "view": {
              "action": {
                "count": 0
              },
              "cumulative_layout_shift": 0,
              "dom_complete": 152800000,
              "dom_content_loaded": 118300000,
              "dom_interactive": 116400000,
              "error": {
                "count": 0
              },
              "first_contentful_paint": 121300000,
              "id": "64308fd4-83f9-48cb-b3e1-1e91f6721230",
              "in_foreground_periods": [],
              "is_active": true,
              "largest_contentful_paint": 121299000,
              "load_event": 152800000,
              "loading_time": 152800000,
              "loading_type": "initial_load",
              "long_task": {
                "count": 0
              },
              "referrer": "",
              "resource": {
                "count": 3
              },
              "time_spent": 3120000000,
              "url": "http://localhost:8080/test.html"
            },
            "_atatus": {
              "document_version": 2,
              "drift": 0,
              "format_version": 2
            },
            "usr": {
              "anonymous_id": "\(expectedUUID)"
            },
            "atatusTags": "service:abc,version:1.1.1,sdk_version:abc,env:test"
        }
        """
        )
    }

    func testWebTelemetryIntegration() throws {
        // Given
        let randomApplicationID: String = .mockRandom()
        let randomUUID: RUMUUID = .mockRandom()

        RUM.enable(with: .mockWith(applicationID: randomApplicationID) {
            $0.uuidGenerator = RUMUUIDGeneratorMock(uuid: randomUUID)
        }, in: core)

        let body = """
        {
          "eventType": "internal_telemetry",
          "event":
            {
              "type": "telemetry",
              "date": 1712069357432,
              "service": "browser-rum-sdk",
              "version": "5.2.0-b93ed472a4f14fbf2bcd1bc2c9faacb4abbeed82",
              "source": "browser",
              "_atatus": { "format_version": 2 },
              "telemetry":
                {
                  "type": "configuration",
                  "configuration":
                    {
                      "session_replay_sample_rate": 100,
                      "use_allowed_tracing_urls": false,
                      "selected_tracing_propagators": [],
                      "default_privacy_level": "allow",
                      "use_excluded_activity_urls": false,
                      "use_worker_url": false,
                      "track_user_interactions": true,
                      "track_resources": true,
                      "track_long_task": true,
                      "session_sample_rate": 100,
                      "telemetry_sample_rate": 100,
                      "use_before_send": false,
                      "use_proxy": false,
                      "allow_fallback_to_local_storage": false,
                      "store_contexts_across_pages": false,
                      "allow_untrusted_events": false
                    },
                  "runtime_env": { "is_local_file": false, "is_worker": false }
                },
              "experimental_features": [],
              "application": { "id": "00000000-aaaa-0000-aaaa-000000000000" },
              "session": { "id": "00000000-aaaa-0000-aaaa-000000000000" },
              "view": {},
              "action": { "id": [] }
            }
        }
        """

        // When
        RUMMonitor.shared(in: core).startView(key: "web-view")
        controller.send(body: body)
        controller.flush()

        // Then
        let expectedUUID = randomUUID.toRUMDataFormat
        let rumMatcher = try XCTUnwrap(core.waitAndReturnRUMEventMatchers().last)
        try rumMatcher.assertItFullyMatches(
            jsonString: """
        {
          "type": "telemetry",
          "date": \(1_712_069_357_432 + 123.dd.toInt64Milliseconds),
          "service": "browser-rum-sdk",
          "version": "5.2.0-b93ed472a4f14fbf2bcd1bc2c9faacb4abbeed82",
          "source": "browser",
          "_atatus": { "format_version": 2 },
          "telemetry":
            {
              "type": "configuration",
              "configuration":
                {
                  "session_replay_sample_rate": 100,
                  "use_allowed_tracing_urls": false,
                  "selected_tracing_propagators": [],
                  "default_privacy_level": "allow",
                  "use_excluded_activity_urls": false,
                  "use_worker_url": false,
                  "track_user_interactions": true,
                  "track_resources": true,
                  "track_long_task": true,
                  "session_sample_rate": 100,
                  "telemetry_sample_rate": 100,
                  "use_before_send": false,
                  "use_proxy": false,
                  "allow_fallback_to_local_storage": false,
                  "store_contexts_across_pages": false,
                  "allow_untrusted_events": false
                },
              "runtime_env": { "is_local_file": false, "is_worker": false }
            },
          "experimental_features": [],
          "application": { "id": "\(randomApplicationID)" },
          "session": { "id": "\(expectedUUID)" },
          "view": {},
          "action": { "id": [] }
        }
        """
        )
    }
}

#endif
