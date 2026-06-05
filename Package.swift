// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "LibHangul",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
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
            resources: [
                .copy("Resources/keyboards")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        .executableTarget(
            name: "demo",
            dependencies: ["LibHangul"],
            path: "Examples",
            exclude: [
                "HybridSolutionDemo.swift",
                "hanja-demo.swift"
            ],
            sources: ["demo.swift"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        .executableTarget(
            name: "TestRunner",
            dependencies: ["LibHangul"],
            path: "Sources/TestRunner",
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
