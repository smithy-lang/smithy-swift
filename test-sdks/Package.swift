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
        .package(url: "https://github.com/awslabs/aws-crt-swift.git", branch: "main"),
        .package(
            name: "AWSJSONTestSDK",
            path: "build/smithyprojections/test-sdks/awsjson-test-sdk/swift-codegen/AWSJSONTestSDK"
        ),
        .package(
            name: "RPCv2CBORTestSDK",
            path: "build/smithyprojections/test-sdks/rpcv2cbor-test-sdk/swift-codegen/RPCv2CBORTestSDK"
        ),
        .package(
            name: "WaitersTestSDK",
            path: "build/smithyprojections/test-sdks/waiters-test-sdk/swift-codegen/WaitersTestSDK"
        ),
    ],
    targets: [
        .testTarget(
            name: "SmithySerializationTests",
            dependencies: [
                .product(name: "SmithySerialization", package: "smithy-swift"),
                .product(name: "RPCv2CBORTestSDK", package: "RPCv2CBORTestSDK"),
            ]
        ),
        .testTarget(
            name: "SmithyCBORTests",
            dependencies: [
                .product(name: "SmithyCBOR", package: "smithy-swift"),
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                .product(name: "RPCv2CBORTestSDK", package: "RPCv2CBORTestSDK"),
            ]
        ),
        .testTarget(
            name: "SmithyJSONTests",
            dependencies: [
                .product(name: "SmithyJSON", package: "smithy-swift"),
                .product(name: "SmithySerialization", package: "smithy-swift"),
                .product(name: "ClientRuntime", package: "smithy-swift"),
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
                .product(name: "AWSJSONTestSDK", package: "AWSJSONTestSDK"),
            ]
        ),
        .testTarget(
            name: "SmithyWaitersTests",
            dependencies: [
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "SmithyWaitersAPI", package: "smithy-swift"),
                .product(name: "WaitersTestSDK", package: "WaitersTestSDK"),
            ],
        ),
    ]
)
