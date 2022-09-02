// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "SmithyClientRuntime",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(name: "SmithyClientRuntime", targets: ["SmithyClientRuntime"]),
        .library(name: "SmithyTestUtil", targets: ["SmithyTestUtil"])
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-crt-swift.git", from: "0.2.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.13.0")
    ],
    targets: [
        .target(
            name: "SmithyClientRuntime",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "XMLCoder", package: "XMLCoder")
            ]
        ),
        .testTarget(
            name: "SmithyClientRuntimeTests",
            dependencies: ["SmithyClientRuntime", "SmithyTestUtil"]
        ),
        .target(
            name: "SmithyTestUtil",
            dependencies: ["SmithyClientRuntime"]
        ),
        .testTarget(
            name: "SmithyTestUtilTests",
            dependencies: ["SmithyTestUtil"]
        )
    ]
)
