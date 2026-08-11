// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`.

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AtatusBenchmarks",
    platforms: [.iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "AtatusBenchmarks",
            targets: ["AtatusBenchmarks"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core", .upToNextMinor(from: "2.5.0"))
    ],
    targets: [
        .target(
            name: "AtatusBenchmarks",
            dependencies: [
                .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core"),
                .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
            ]
        )
    ]
)
