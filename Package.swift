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
        )
    ],
    targets: [
        .target(
            name: "LibHangul",
            path: "Sources/LibHangul"
        ),
        .testTarget(
            name: "LibHangulTests",
            dependencies: ["LibHangul"],
            path: "Tests/LibHangulTests"
        )
    ]
)
