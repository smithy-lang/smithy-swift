// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SmithySwiftCodegenTests",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    dependencies: [
        .package(name: "smithy-swift", path: ".."),
        .package(
            name: "WaitersTestSDK",
            path: "build/smithyprojections/test-sdks/waiters-test-sdk/swift-codegen"
        ),
    ],
    targets: [
        .testTarget(
            name: "SmithyWaitersTests",
            dependencies: [
                .product(name: "WaitersTestSDK", package: "WaitersTestSDK"),
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "SmithyWaitersAPI", package: "smithy-swift"),
            ],
        ),
    ]
)
