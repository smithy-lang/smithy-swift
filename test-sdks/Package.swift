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
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
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
            ]
        ),
        .testTarget(
            name: "SmithyTests",
            dependencies: [
                .product(name: "Smithy", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "ClientRuntimeTests",
            dependencies: [
                .product(name: "ClientRuntime", package: "smithy-swift"),
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
                .product(name: "SmithyStreams", package: "smithy-swift"),
                .product(name: "Logging", package: "swift-log"),
            ],
            resources: [ .process("Resources") ]
        ),
        .testTarget(
            name: "SmithySwiftNIOTests",
            dependencies: [
                .product(name: "SmithySwiftNIO", package: "smithy-swift"),
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyHTTPClientTests",
            dependencies: [
                .product(name: "SmithyHTTPClient", package: "smithy-swift"),
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "SmithyHTTPAPI", package: "smithy-swift"),
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .testTarget(
            name: "SmithyXMLTests",
            dependencies: [
                .product(name: "SmithyXML", package: "smithy-swift"),
                .product(name: "SmithySerialization", package: "smithy-swift"),
                .product(name: "ClientRuntime", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyHTTPAuthTests",
            dependencies: [
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "SmithyHTTPAuth", package: "smithy-swift"),
                .product(name: "SmithyHTTPAPI", package: "smithy-swift"),
                .product(name: "SmithyIdentity", package: "smithy-swift"),
                .product(name: "ClientRuntime", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyHTTPAuthAPITests",
            dependencies: [
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "SmithyHTTPAuthAPI", package: "smithy-swift"),
                .product(name: "ClientRuntime", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyFormURLTests",
            dependencies: [
                .product(name: "SmithyFormURL", package: "smithy-swift"),
                .product(name: "ClientRuntime", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyTimestampsTests",
            dependencies: [
                .product(name: "SmithyTimestamps", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyTestUtilTests",
            dependencies: [
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyEventStreamsTests",
            dependencies: [
                .product(name: "SmithyEventStreams", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyIdentityTests",
            dependencies: [
                .product(name: "SmithyIdentity", package: "smithy-swift"),
                .product(name: "Smithy", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyWaitersAPITests",
            dependencies: [
                .product(name: "SmithyWaitersAPI", package: "smithy-swift"),
                .product(name: "Smithy", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyRetriesTests",
            dependencies: [
                .product(name: "SmithyRetries", package: "smithy-swift"),
                .product(name: "SmithyRetriesAPI", package: "smithy-swift"),
                .product(name: "ClientRuntime", package: "smithy-swift"),
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyHTTPAPITests",
            dependencies: [
                .product(name: "SmithyHTTPAPI", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyStreamsTests",
            dependencies: [
                .product(name: "SmithyStreams", package: "smithy-swift"),
                .product(name: "Smithy", package: "smithy-swift"),
            ]
        ),
        .testTarget(
            name: "SmithyCodegenCoreTests",
            dependencies: [
                .product(name: "SmithyCodegenCore", package: "smithy-swift"),
            ],
            resources: [ .process("Resources") ]
        ),
    ]
)
