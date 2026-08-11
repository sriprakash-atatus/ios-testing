/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddFlags` -> `AtatusFlags`, `ddInternal`
// -> `AtatusInternal`; renamed `dd*` types to `Atatus*`; renamed `clientToken` to `licenseKey`;
// rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusFlags

final class FlagAssignmentsRequestTests: XCTestCase {
    private let testURL = URL(string: "https://test.example.com/precompute-assignments")!

    func testFlagAssignmentsRequest() throws {
        // Given
        let evaluationContext = FlagsEvaluationContext(
            targetingKey: "user123",
            attributes: [
                "plan": .string("premium"),
                "userId": .string("123")
            ]
        )
        let context = AtatusContext.mockWith(
            licenseKey: "test-token",
            env: "production",
            sdkVersion: "3.5.1",
            additionalContext: [RUMCoreContext.mockWith(applicationID: "test-app-id")]
        )
        let customHeaders = ["X-Custom-Header": "custom-value"]
        let expectedBody = """
        {
          "data" : {
            "attributes" : {
              "env" : {
                "dd_env" : "production",
                "name" : "production"
              },
              "source" : {
                "sdk_name" : "atatus-sdk-ios",
                "sdk_version" : "3.5.1"
              },
              "subject" : {
                "targeting_attributes" : {
                  "plan" : "premium",
                  "userId" : "123"
                },
                "targeting_key" : "user123"
              }
            },
            "type" : "precompute-assignments-request"
          }
        }
        """

        // When
        let request = try URLRequest.flagAssignmentsRequest(
            url: testURL,
            evaluationContext: evaluationContext,
            context: context,
            customHeaders: customHeaders
        )

        // Then
        XCTAssertEqual(request.url, testURL)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.api+json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Encoding"), "gzip, deflate, br")
        XCTAssertEqual(request.value(forHTTPHeaderField: "dd-client-token"), "test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "dd-application-id"), "test-app-id")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom-Header"), "custom-value")
        let actualBody = try XCTUnwrap(request.httpBody.flatMap { String(data: $0, encoding: .utf8) })
        XCTAssertEqual(actualBody.normalizedJSON, expectedBody.normalizedJSON)
    }
}

// MARK: - Test Helpers

extension String {
    fileprivate var normalizedJSON: String {
        // Normalizes JSON string by parsing and re-serializing with sorted keys and pretty printing.
        // This allows for comparing JSON content regardless of formatting or key ordering.
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let normalized = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .prettyPrinted]),
              let result = String(data: normalized, encoding: .utf8) else {
            return self
        }
        return result
    }
}
