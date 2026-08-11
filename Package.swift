// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the `dd` name to `Atatus` in comments and docs.

// swift-tools-version: 6.0

import PackageDescription
import Foundation

let internalSwiftSettings: [SwiftSetting] = ProcessInfo.processInfo.environment["AT_BENCHMARK"] != nil ?
    [.define("AT_BENCHMARK")] : []

let package = Package(
    name: "Atatus",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS("12.6"),
        .watchOS(.v7),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "AtatusCore",
            targets: ["AtatusCore"]
        ),
        .library(
            name: "AtatusLogs",
            targets: ["AtatusLogs"]
        ),
        .library(
            name: "AtatusTrace",
            targets: ["AtatusTrace"]
        ),
        .library(
            name: "AtatusRUM",
            targets: ["AtatusRUM"]
        ),
        .library(
            name: "AtatusSessionReplay",
            targets: ["AtatusSessionReplay"]
        ),
        .library(
            name: "AtatusCrashReporting",
            targets: ["AtatusCrashReporting"]
        ),
        .library(
            name: "AtatusWebViewTracking",
            targets: ["AtatusWebViewTracking"]
        ),
        .library(
            name: "AtatusFlags",
            targets: ["AtatusFlags"]
        ),
        .library(
            name: "AtatusProfiling",
            targets: ["AtatusProfiling"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kstenerud/KSCrash.git", from: "2.5.1"),
        .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core", .upToNextMinor(from: "2.5.0")),
    ],
    targets: [
        .target(
            name: "AtatusCore",
            dependencies: [
                .target(name: "AtatusInternal"),
                .target(name: "AtatusPrivate"),
            ],
            path: "AtatusCore",
            sources: ["Sources"],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [.define("SPM_BUILD")] + internalSwiftSettings
        ),
        .target(
            name: "AtatusPrivate",
            path: "AtatusCore/Private"
        ),

        .target(
            name: "AtatusInternal",
            path: "AtatusInternal/Sources",
            swiftSettings: internalSwiftSettings
        ),
        .testTarget(
            name: "AtatusInternalTests",
            dependencies: [
                .target(name: "AtatusInternal"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusInternal/Tests"
        ),

        .target(
            name: "AtatusLogs",
            dependencies: [
                .target(name: "AtatusInternal"),
            ],
            path: "AtatusLogs/Sources"
        ),
        .testTarget(
            name: "AtatusLogsTests",
            dependencies: [
                .target(name: "AtatusLogs"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusLogs/Tests"
        ),

        .target(
            name: "AtatusTrace",
            dependencies: [
                .target(name: "AtatusInternal"),
                .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core")
            ],
            path: "AtatusTrace/Sources",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "AtatusTraceTests",
            dependencies: [
                .target(name: "AtatusTrace"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusTrace/Tests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),

        .target(
            name: "AtatusRUM",
            dependencies: [
                .target(name: "AtatusInternal"),
                .target(name: "AtatusRUMPrivate"),
            ],
            path: "AtatusRUM",
            sources: ["Sources"],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [.define("SPM_BUILD")] + internalSwiftSettings
        ),
        .target(
            name: "AtatusRUMPrivate",
            path: "AtatusRUM/Private"
        ),
        .testTarget(
            name: "AtatusRUMTests",
            dependencies: [
                .target(name: "AtatusRUM"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusRUM/Tests"
        ),

        .target(
            name: "AtatusCrashReporting",
            dependencies: [
                .target(name: "AtatusInternal"),
                .product(name: "Recording", package: "KSCrash"),
                .product(name: "Filters", package: "KSCrash")
            ],
            path: "AtatusCrashReporting",
            sources: ["Sources"],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "AtatusCrashReportingTests",
            dependencies: [
                .target(name: "AtatusCrashReporting"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusCrashReporting/Tests"
        ),

        .target(
            name: "AtatusWebViewTracking",
            dependencies: [
                .target(name: "AtatusInternal"),
            ],
            path: "AtatusWebViewTracking/Sources"
        ),
        .testTarget(
            name: "AtatusWebViewTrackingTests",
            dependencies: [
                .target(name: "AtatusWebViewTracking"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusWebViewTracking/Tests"
        ),

        .target(
            name: "AtatusSessionReplay",
            dependencies: ["AtatusInternal"],
            path: "AtatusSessionReplay/Sources"
        ),
        .testTarget(
            name: "AtatusSessionReplayTests",
            dependencies: [
                .target(name: "AtatusSessionReplay"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusSessionReplay/Tests",
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        
        .target(
            name: "AtatusProfiling",
            dependencies: [
                .target(name: "AtatusInternal"),
                .target(name: "AtatusMachProfiler")
            ],
            path: "AtatusProfiling",
            sources: ["Sources"],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: internalSwiftSettings
        ),
        .target(
            name: "AtatusMachProfiler",
            path: "AtatusProfiling/Mach"
        ),
        .testTarget(
            name: "AtatusProfilingTests",
            dependencies: [
                .target(name: "AtatusMachProfiler"),
                .target(name: "AtatusProfiling"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusProfiling/Tests",
            swiftSettings: [.interoperabilityMode(.Cxx)] + internalSwiftSettings
        ),

        .target(
            name: "AtatusFlags",
            dependencies: [
                .target(name: "AtatusInternal"),
            ],
            path: "AtatusFlags/Sources"
        ),
        .testTarget(
            name: "AtatusFlagsTests",
            dependencies: [
                .target(name: "AtatusFlags"),
                .target(name: "TestUtilities"),
            ],
            path: "AtatusFlags/Tests"
        ),

        .target(
            name: "TestUtilities",
            dependencies: [
                .target(name: "AtatusCore"),
                .target(name: "AtatusPrivate"),
                .target(name: "AtatusInternal"),
                .target(name: "AtatusLogs"),
                .target(name: "AtatusRUM"),
                .target(name: "AtatusSessionReplay"),
                .target(name: "AtatusTrace"),
                .target(name: "AtatusCrashReporting"),
                .target(name: "AtatusWebViewTracking"),
                .target(name: "AtatusFlags"),
            ],
            path: "TestUtilities/Sources",
            swiftSettings: [.define("SPM_BUILD")] + internalSwiftSettings
        )
    ],
    swiftLanguageModes: [.v5],
    cxxLanguageStandard: .cxx17
)

// If the `AT_TEST_UTILITIES_ENABLED` development ENV is set, export additional utility packages.
// To set this ENV for Xcode projects that fetch this package locally, use `open --env AT_TEST_UTILITIES_ENABLED path/to/<project or workspace>`.
if ProcessInfo.processInfo.environment["AT_TEST_UTILITIES_ENABLED"] != nil {
    package.products.append(
        .library(
            name: "TestUtilities",
            targets: ["TestUtilities"]
        )
    )
}
