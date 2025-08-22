// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "LibHangul",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "LibHangul",
            targets: ["LibHangul"]
        ),
        .executable(
            name: "HybridSolutionDemo",
            targets: ["HybridSolutionDemo"]
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
        .executableTarget(
            name: "HybridSolutionDemo",
            dependencies: ["LibHangul"],
            path: "."
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
    swiftLanguageVersions: [.v6]
)
