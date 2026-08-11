// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the `dd` name to
// `Atatus` in comments and docs.

// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "TestUtilities",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v12),
        .watchOS(.v7),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "TestUtilities",
            targets: ["TestUtilities"]
        ),
    ],
    dependencies: [
        .package(name: "Atatus", path: ".."),
    ],
    targets: [
        .target(
            name: "TestUtilities",
            dependencies: [
                .product(name: "AtatusCore", package: "Atatus"),
                .product(name: "AtatusRUM", package: "Atatus"),
                .product(name: "AtatusLogs",package: "Atatus"),
                .product(name: "AtatusTrace",package: "Atatus"),
                .product(name: "AtatusCrashReporting",package: "Atatus"),
                .product(name: "AtatusSessionReplay", package: "Atatus"),
                .product(name: "AtatusWebViewTracking",package: "Atatus")
            ],
            path: ".",
            sources: ["Sources"],
            swiftSettings: [.define("SPM_BUILD")]
        ),
    ]
)
