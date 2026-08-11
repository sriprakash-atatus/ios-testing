/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `clientToken` to `licenseKey`; rebranded the licence header.

import Foundation
import AtatusInternal

extension URLRequest {
    internal static func flagAssignmentsRequest(
        url: URL,
        evaluationContext: FlagsEvaluationContext,
        context: AtatusContext,
        customHeaders: [String: String]?
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue(context.licenseKey, forHTTPHeaderField: "dd-client-token")

        if let applicationId = context.additionalContext(ofType: RUMCoreContext.self)?.applicationID {
            request.setValue(applicationId, forHTTPHeaderField: "dd-application-id")
        }

        if let customHeaders {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let requestBody = FlagAssignmentsRequestBody(
            environment: FlagAssignmentsRequestBody.Environment(
                name: context.env,
                atatusEnvironment: context.env
            ),
            source: FlagAssignmentsRequestBody.Source(
                sdkName: "atatus-sdk-ios",
                sdkVersion: context.sdkVersion
            ),
            subject: FlagAssignmentsRequestBody.Subject(
                targetingKey: evaluationContext.targetingKey,
                targetingAttributes: evaluationContext.attributes
            )
        )

        let encoder = JSONEncoder.dd.default()
        request.httpBody = try encoder.encode(requestBody)

        return request
    }
}

internal struct FlagAssignmentsRequestBody {
    struct Subject: Encodable {
        private enum CodingKeys: String, CodingKey {
            case targetingKey = "targeting_key"
            case targetingAttributes = "targeting_attributes"
        }

        let targetingKey: String
        let targetingAttributes: [String: AnyValue]
    }

    struct Environment: Encodable {
        private enum CodingKeys: String, CodingKey {
            case name
            case atatusEnvironment = "dd_env"
        }

        let name: String
        let atatusEnvironment: String
    }

    struct Source: Encodable {
        private enum CodingKeys: String, CodingKey {
            case sdkName = "sdk_name"
            case sdkVersion = "sdk_version"
        }

        let sdkName: String
        let sdkVersion: String
    }

    let environment: Environment
    let source: Source
    let subject: Subject
}

extension FlagAssignmentsRequestBody: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case data
        case attributes
        case flags
        case environment = "env"
        case source
        case subject
    }

    func encode(to encoder: any Encoder) throws {
        var rootContainer = encoder.container(keyedBy: CodingKeys.self)

        var dataContainer = rootContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        try dataContainer.encode("precompute-assignments-request", forKey: .type)

        var attributesContainer = dataContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .attributes)
        try attributesContainer.encode(environment, forKey: .environment)
        try attributesContainer.encode(source, forKey: .source)
        try attributesContainer.encode(subject, forKey: .subject)
    }
}
