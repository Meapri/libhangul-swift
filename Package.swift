// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "LibHangul",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "LibHangul",
            targets: ["LibHangul"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LibHangul",
            dependencies: [],
            path: "Sources/LibHangul",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        .testTarget(
            name: "LibHangulTests",
            dependencies: ["LibHangul"],
            path: "Tests/LibHangulTests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
