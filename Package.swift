// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "smithy-swift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(name: "ClientRuntime", targets: ["ClientRuntime"]),
        .library(name: "SmithyReadWrite", targets: ["SmithyReadWrite"]),
        .library(name: "SmithyXML", targets: ["SmithyXML"]),
        .library(name: "SmithyTestUtil", targets: ["SmithyTestUtil"]),
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-crt-swift.git", exact: "0.17.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", exact: "0.17.0")
    ],
    targets: [
        .target(
            name: "ClientRuntime",
            dependencies: [
                "SmithyXML",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "XMLCoder", package: "XMLCoder")
            ]
        ),
        .testTarget(name: "ClientRuntimeTests", dependencies: ["ClientRuntime", "SmithyTestUtil"]),
        .target(name: "SmithyReadWrite"),
        .target(name: "SmithyXML", dependencies: ["SmithyReadWrite", "SmithyTimestamps"]),
        .testTarget(name: "SmithyXMLTests", dependencies: ["SmithyXML"]),
        .target(name: "SmithyTimestamps"),
        .testTarget(name: "SmithyTimestampsTests", dependencies: ["SmithyTimestamps"]),
        .target(name: "SmithyTestUtil", dependencies: ["ClientRuntime"]),
        .testTarget(name: "SmithyTestUtilTests", dependencies: ["SmithyTestUtil"]),
    ]
)
