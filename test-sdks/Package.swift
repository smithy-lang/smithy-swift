// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SmithySwiftTests",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    dependencies: [
        // Use local smithy-swift and latest unreleased (main branch) aws-crt-swift
        .package(name: "smithy-swift", path: ".."),
        .package(url: "https://github.com/awslabs/aws-crt-swift.git", branch: "main"),

        // ClientRuntime tests use swift-log.  Keep this spec same as in smithy-swift
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),

        // Generated test SDKs.  Models are in build/model.  Use them where Smithy generates them.
        // Run bash script ./scripts/codegen.sh from smithy-swift root to generate or regenerate these files
        testSDKPackage("AWSJSON"),
        testSDKPackage("JSONName"),
        testSDKPackage("MaxRecursion"),
        testSDKPackage("NullTolerance"),
        testSDKPackage("StringSerializer"),
        testSDKPackage("Waiters"),
    ],
    targets: [
        .testTarget(
            name: "SmithySerializationTests",
            dependencies: [
                .product(name: "SmithySerialization", package: "smithy-swift"),
                testSDKProduct("StringSerializer"),
            ]
        ),
        .testTarget(
            name: "SmithyCBORTests",
            dependencies: [
                .product(name: "SmithyCBOR", package: "smithy-swift"),
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
                testSDKProduct("MaxRecursion"),
            ]
        ),
        .testTarget(
            name: "SmithyJSONTests",
            dependencies: [
                .product(name: "SmithyJSON", package: "smithy-swift"),
                .product(name: "SmithySerialization", package: "smithy-swift"),
                .product(name: "ClientRuntime", package: "smithy-swift"),
                .product(name: "SmithyTimestamps", package: "smithy-swift"),
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
                testSDKProduct("AWSJSON"),
                testSDKProduct("JSONName"),
                testSDKProduct("NullTolerance"),
            ]
        ),
        .testTarget(
            name: "SmithyWaitersTests",
            dependencies: [
                .product(name: "Smithy", package: "smithy-swift"),
                .product(name: "SmithyWaitersAPI", package: "smithy-swift"),
                testSDKProduct("Waiters"),
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

private func testSDKPackage(_ name: String) -> Package.Dependency {
    .package(
        name: "\(name)TestSDK",
        path: "build/smithyprojections/test-sdks/\(name)/swift-codegen/\(name)TestSDK"
    )
}

private func testSDKProduct(_ name: String) -> Target.Dependency {
    .product(name: "\(name)TestSDK", package: "\(name)TestSDK")
}
