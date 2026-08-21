/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; renamed the build `variant` to `appName`; renamed the `_dd` attribute prefix to `_atatus`; renamed
// the `ddsource` / `ddtags` query parameters to `atatus_source` / `atatustags`; rebranded the `dd`
// name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// A `String` value naming the attribute.
///
/// Dot syntax can be used to nest objects:
///
///     logger.addAttribute(forKey: "person.name", value: "Adam")
///     logger.addAttribute(forKey: "person.age", value: 32)
///
///     // When seen in Atatus console:
///     {
///         person: {
///             name: "Adam"
///             age: 32
///         }
///     }
///
/// - Important
/// Values can be nested up to 8 levels deep. Keys using more than 8 levels will be sanitized by the SDK.
///
public typealias AttributeKey = String

/// Any `Encodable` value of the attribute (`String`, `Int`, `Bool`, `Date` etc.).
///
/// Custom `Encodable` types are supported as well with nested encoding containers:
///
///     struct Person: Codable {
///         let name: String
///         let age: Int
///         let address: Address
///     }
///
///     struct Address: Codable {
///         let city: String
///         let street: String
///     }
///
///     let address = Address(city: "Paris", street: "Champs Elysees")
///     let person = Person(name: "Adam", age: 32, address: address)
///
///     // When seen in Atatus console:
///     {
///         person: {
///             name: "Adam"
///             age: 32
///             address: {
///                 city: "Paris",
///                 street: "Champs Elysees"
///             }
///         }
///     }
///
/// - Important
/// Attributes in Atatus console can be nested up to 10 levels deep. If number of nested attribute levels
/// defined as sum of key levels and value levels exceeds 10, the data may not be delivered.
///
public typealias AttributeValue = Encodable

// MARK: - Internal attributes

/// Internal attributes, passed from cross-platform bridge or internal integrations.
/// Used to configure or override SDK internal features and attributes for the need of cross-platform SDKs (e.g. React Native SDK).
public struct CrossPlatformAttributes {
    /// Custom app version passed from CP SDK. Used for all events issued by the SDK (both coming from cross-platform SDK and produced internally, like RUM long tasks).
    /// It should replace the default native `version` read from `Info.plist`.
    /// Expects `String` value (semantic version).
    public static let version: String = "_atatus.version"

    /// Custom SDK version passed from CP SDK. Used for all events issued by the SDK (both coming from cross-platform SDK and produced internally, like RUM long tasks).
    /// It should replace the default native `sdkVersion`.
    /// Expects `String` value (semantic version).
    public static let sdkVersion: String = "_atatus.sdk_version"

    /// Custom SDK `source` passed from CP SDK. Used for all events issued by the SDK (both coming from cross-platform SDK and produced internally, like RUM long tasks).
    /// It should replace the default native `atatusSource` value (`"ios"`).
    /// Expects `String` value.
    public static let atatusSource: String = "_atatus.source"

    /// Custom AppName passed from a CP SDK. This is the 'flavor' parameter used in Android and Flutter, Used for all events issued by the SDK (both coming from cross-platform
    /// SDK and produced internally, like RUM long tasks).
    /// It does not replace any default native properties as iOS does not have the concept of 'flavors' or variants.
    // ATCHG: `_dd` attribute prefix renamed to `_atatus` and the `variant` key renamed to
    // `app_name`, matching the Atatus Android agent.
    public static let appName: String = "_atatus.app_name"

    /// A custom unique id that identifies this build of the application, used from symbolication and deobfuscation
    ///  Id does not replace any default native properties and is sent in addition to version and build number
    public static let buildId: String = "_atatus.build_id"

    /// Event timestamp passed from CP SDK. Used for all RUM events issued by cross platform SDK.
    /// It should replace event time obtained from `DateProvider` to ensure that events are not skewed due to time difference in native and cross-platform SDKs.
    /// Expects `Int64` value (milliseconds).
    public static let timestampInMilliseconds = "_atatus.timestamp"

    /// Custom "source type" of the error passed from CP SDK. Used in RUM errors reported by cross platform SDK.
    /// It names the language or platform of the RUM error stack trace, so the SCI backend knows how to symbolicate it.
    /// Expects `String` value.
    public static let errorSourceType = "_atatus.error.source_type"

    /// Custom attribute of the error passed from CP SDK. Used in RUM errors reported by cross platform SDK.
    /// It flags the error has being fatal for the host application.
    /// Expects `Bool` value.
    public static let errorIsCrash = "_atatus.error.is_crash"

    /// Trace ID passed from CP SDK. Used in RUM resources created by cross platform SDK.
    /// When cross-platform SDK injects tracing headers to intercepted resource, we pass tracing information through this attribute
    /// and send it within the RUM resource, so the RUM backend can issue corresponding APM span on behalf of the mobile app.
    /// Expects `String` value.
    public static let traceID = "_atatus.trace_id"

    /// Span ID passed from CP SDK. Used in RUM resources created by cross platform SDK.
    /// When cross-platform SDK injects tracing headers to intercepted resource, we pass tracing information through this attribute
    /// and send it within the RUM resource, so the RUM backend can issue corresponding APM span on behalf of the mobile app.
    ///
    /// Expects a `String` holding the id in the same representation the `traceparent` header carries: 16 lower-case
    /// hex characters. The RUM resource *is* the client span for a cross-platform app - no separate span payload is
    /// uploaded for it - so this id has to string-match the id the receiving service records as its parent, and that
    /// one comes from `traceparent`. A decimal id is still accepted for agents predating this contract.
    public static let spanID = "_atatus.span_id"

    /// Parent span ID passed from CP SDK. Used in RUM resources created by cross platform SDK.
    /// When cross-platform SDK injects tracing headers to intercepted resource, we pass tracing information through this attribute
    /// and send it within the RUM resource, so the RUM backend can issue corresponding APM span on behalf of the mobile app.
    ///
    /// Expects a `String` in the same representation as ``spanID``: 16 lower-case hex characters, decimal accepted
    /// for backwards compatibility. An all-zero id means "no parent" and is ignored.
    public static let parentSpanID = "_atatus.parent_span_id"

    /// Trace sample rate applied to RUM resources created by cross platform SDK.
    /// We send cross-platform SDK's sample rate within RUM resource in order to provide accurate visibility into what settings are
    /// configured at the SDK level. This gets displayed on APM's traffic ingestion control page.
    /// Expects `Double` value between `0.0` and `1.0`.
    public static let rulePSR = "_atatus.rule_psr"

    /// Custom attribute passed when starting GraphQL RUM resources from a cross platform SDK.
    /// It sets the GraphQL operation name if it was defined by the developer.
    /// Expects `String` value.
    public static let graphqlOperationName = "_atatus.graphql.operation_name"

    /// Custom attribute passed when starting GraphQL RUM resources from a cross platform SDK.
    /// It sets the GraphQL operation type.
    /// Expects `String` value of either `query`, `mutation` or `subscription`.
    public static let graphqlOperationType = "_atatus.graphql.operation_type"

    /// Custom attribute passed when starting GraphQL RUM resources from a cross platform SDK.
    /// It sets the GraphQL payload as a JSON string when it is specified.
    /// Expects `String` value.
    public static let graphqlPayload = "_atatus.graphql.payload"

    /// Custom attribute passed when starting GraphQL RUM resources resources from a cross platform SDK.
    /// It sets the GraphQL variables as a JSON string if they were defined by the developer.
    /// Expects `String` value.
    public static let graphqlVariables = "_atatus.graphql.variables"

    /// Custom attribute passed when completing GraphQL RUM resources that contain errors in the response.
    /// It sets the GraphQL errors array as a JSON string.
    /// Expects `String` value containing a JSON array of errors.
    public static let graphqlErrors = "_atatus.graphql.errors"

    /// Override the `source_type` of errors reported by the native crash handler. This is used on
    /// platforms that can supply extra steps or information on a native crash (such as Unity's IL2CPP)
    public static let nativeSourceType = "_atatus.native_source_type"

    /// Add "binary images" to the reportted error to assist with symbolication. Used by Unity for IL2CPP symbolicaiton
    public static let includeBinaryImages = "_atatus.error.include_binary_images"

    /// Custom Flutter vital - First Build Complete. The amount of time between a route change (the start of a view) and when the first
    /// `build` method is complete. In nanoseconds since view start
    public static let flutterFirstBuildComplete: String = "_atatus.performance.first_build_complete"

    /// Custom value for Interaction To Next view.
    /// For Flutter this is the amount of time between an action occurring and the First Build Complete occurring on the next view.
    public static let customINVValue: String = "_atatus.view.custom_inv_value"

    /// Request headers passed from Cross-Platform SDK or captured from native URLSession interception.
    /// Used in RUM resources to transport request headers through the RUM command pipeline.
    /// Expects `[String: String]` value containing header keys and values.
    public static let requestHeaders = "_atatus.request_headers"

    /// Response headers passed from Cross-Platform SDK or captured from native URLSession interception.
    /// Used in RUM resources to transport response headers through the RUM command pipeline.
    /// Expects `[String: String]` value containing header keys and values.
    public static let responseHeaders = "_atatus.response_headers"

    /// Indicates whether the resource was served from the device's local cache, captured from native URLSession interception.
    /// Expects `Bool` value.
    public static let localCacheHit = "_atatus.local_cache_hit"

    /// Span kind passed from CP SDK. Used in RUM resources created by cross platform SDK.
    ///
    /// Every resource the agent reports is an outgoing request, so this is always `client` - including for the first
    /// span of a trace. It is re-published on the event under the flat `span.kind` key, which is what the rest of
    /// Atatus uses (`Tracer.Tags.kind` / `OTTags.spanKind`) and what the backend reads to decide a span's kind.
    /// Leaving it under its `_atatus.` name would leave the canonical kind unset and the span would fall back to
    /// `server` in the trace view while the copy showed up separately as a custom attribute.
    /// Expects `String` value.
    public static let spanKind = "_atatus.span.kind"

    /// Resource duration, in **nanoseconds**, as measured by a cross platform SDK.
    ///
    /// Cross-platform SDKs observe the request on their own side of the platform channel, so they know how long it
    /// actually took; the duration derived here spans the two channel hops instead. When this attribute is present it
    /// overrides ``RUMResourceEvent/Resource/duration``. Expects an `Int` value.
    public static let resourceDuration = "_atatus.resource.duration"
}

/// HTTP header names used to pass GraphQL metadata from the application to the SDK.
/// These headers are read from intercepted requests and mapped to internal attributes.
public struct GraphQLHeaders {
    /// HTTP header name for GraphQL operation name.
    public static let operationName: String = "_atatus-custom-header-graph-ql-operation-name"

    /// HTTP header name for GraphQL operation type.
    public static let operationType: String = "_atatus-custom-header-graph-ql-operation-type"

    /// HTTP header name for GraphQL variables.
    public static let variables: String = "_atatus-custom-header-graph-ql-variables"

    /// HTTP header name for GraphQL payload.
    public static let payload: String = "_atatus-custom-header-graph-ql-payload"
}

extension URLRequest {
    /// Whether this request contains GraphQL headers indicating a GraphQL request.
    public var hasGraphQLHeaders: Bool {
        value(forHTTPHeaderField: GraphQLHeaders.operationName) != nil ||
        value(forHTTPHeaderField: GraphQLHeaders.operationType) != nil ||
        value(forHTTPHeaderField: GraphQLHeaders.variables) != nil ||
        value(forHTTPHeaderField: GraphQLHeaders.payload) != nil
    }
}

public struct LaunchArguments {
    /// Each product should consider this argument to offer simple debugging experience. 
    /// For example, if this flag is present it can use no sampling.
    public static let Debug = "AT_DEBUG"
}

extension AtatusExtension where ExtendedType == [String: Any] {
    public var swiftAttributes: [String: Encodable] {
        type.mapValues { AnyEncodable($0) }
    }

    public var swiftSendableAttributes: [String: Encodable & Sendable] {
        type.mapValues { AnyEncodable($0) }
    }
}

extension AtatusExtension where ExtendedType == [String: Encodable] {
    public var objCAttributes: [String: Any] {
        type.compactMapValues { ($0 as? AnyEncodable)?.value }
    }
}

extension AtatusExtension where ExtendedType == [String: Encodable & Sendable] {
    public var objCAttributes: [String: Any] {
        type.compactMapValues { ($0 as? AnyEncodable)?.value }
    }
}

extension AttributeValue {
    /// Instance Atatus extension point.
    ///
    /// `AttributeValue` aka `Encodable` is a protocol and cannot be extended
    /// with conformance to`AtatusExtension`, so we need to define the `dd`
    /// endpoint.
    public var dd: AtatusExtension<AttributeValue> {
        AtatusExtension(self)
    }
}

extension AtatusExtension where ExtendedType == AttributeValue {
    public func decode<T>(_: T.Type = T.self) -> T? {
        switch type {
        case let encodable as _AnyEncodable:
            return encodable.value as? T
        case let val as T:
            return val
        default:
            return nil
        }
    }
}
