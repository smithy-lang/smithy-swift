// swift-tools-version:5.9

import Foundation
import PackageDescription

// Define libxml2 only on Linux, since it causes warnings
// about "pkgconfig not found" on Mac
#if os(Linux)
let libXML2DependencyOrNil: Target.Dependency? = "libxml2"
let libXML2TargetOrNil: Target? = Target.systemLibrary(
    name: "libxml2",
    pkgConfig: "libxml-2.0",
    providers: [
        .apt(["libxml2 libxml2-dev"]),
        .yum(["libxml2 libxml2-devel"])
    ]
)
#else
let libXML2DependencyOrNil: Target.Dependency? = nil
let libXML2TargetOrNil: Target? = nil
#endif

let package = Package(
    name: "smithy-swift",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "Smithy", targets: ["Smithy"]),
        .library(name: "SmithySerialization", targets: ["SmithySerialization"]),
        .library(name: "SmithyAWSJSON", targets: ["SmithyAWSJSON"]),
        .library(name: "SmithyRPCv2CBOR", targets: ["SmithyRPCv2CBOR"]),
        .library(name: "ClientRuntime", targets: ["ClientRuntime"]),
        .library(name: "SmithyRetriesAPI", targets: ["SmithyRetriesAPI"]),
        .library(name: "SmithyRetries", targets: ["SmithyRetries"]),
        .library(name: "SmithyReadWrite", targets: ["SmithyReadWrite"]),
        .library(name: "SmithyXML", targets: ["SmithyXML"]),
        .library(name: "SmithyCBOR", targets: ["SmithyCBOR"]),
        .library(name: "SmithyJSON", targets: ["SmithyJSON"]),
        .library(name: "SmithyFormURL", targets: ["SmithyFormURL"]),
        .library(name: "SmithyTimestamps", targets: ["SmithyTimestamps"]),
        .library(name: "SmithyIdentity", targets: ["SmithyIdentity"]),
        .library(name: "SmithyIdentityAPI", targets: ["SmithyIdentityAPI"]),
        .library(name: "SmithyHTTPAPI", targets: ["SmithyHTTPAPI"]),
        .library(name: "SmithyHTTPClient", targets: ["SmithyHTTPClient"]),
        .library(name: "SmithyHTTPAuth", targets: ["SmithyHTTPAuth"]),
        .library(name: "SmithyHTTPAuthAPI", targets: ["SmithyHTTPAuthAPI"]),
        .library(name: "SmithyEventStreamsAPI", targets: ["SmithyEventStreamsAPI"]),
        .library(name: "SmithyEventStreamsAuthAPI", targets: ["SmithyEventStreamsAuthAPI"]),
        .library(name: "SmithyEventStreams", targets: ["SmithyEventStreams"]),
        .library(name: "SmithyStreams", targets: ["SmithyStreams"]),
        .library(name: "SmithyChecksumsAPI", targets: ["SmithyChecksumsAPI"]),
        .library(name: "SmithyChecksums", targets: ["SmithyChecksums"]),
        .library(name: "SmithyWaitersAPI", targets: ["SmithyWaitersAPI"]),
        .library(name: "SmithyTestUtil", targets: ["SmithyTestUtil"]),
        .library(name: "SmithySwiftNIO", targets: ["SmithySwiftNIO"]),
        .library(name: "SmithyTelemetryAPI", targets: ["SmithyTelemetryAPI"]),
        .library(name: "SmithyHTTPClientAPI", targets: ["SmithyHTTPClientAPI"]),
        .library(name: "SmithyCodegenCore", targets: ["SmithyCodegenCore"]),
        .plugin(name: "SmithyCodeGeneratorPlugin", targets: ["SmithyCodeGeneratorPlugin"]),
    ],
    dependencies: {
        var dependencies: [Package.Dependency] = [
            crtDependency,
            .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.0"),
            .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
            .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.22.0"),
        ]

        let isDocCEnabled = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_ENABLE_DOCC"] != nil
        if isDocCEnabled {
            dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
        }
        return dependencies
    }(),
    targets: runtimeTargets + runtimeTestTargets
)

var crtDependency: Package.Dependency {
    let useCRTFromMain = ProcessInfo.processInfo.environment["AWS_SWIFT_SDK_USE_PRERELEASE_CRT"] != nil
    return if useCRTFromMain {
        .package(url: "https://github.com/awslabs/aws-crt-swift", branch: "main")
    } else {
        .package(url: "https://github.com/awslabs/aws-crt-swift", from: "0.63.0")
    }
}

var runtimeTargets: [PackageDescription.Target] {
    [
        .target(
            name: "Smithy",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "SmithySerialization",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyTelemetryAPI",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyHTTPClientAPI",
            dependencies: [
                "Smithy",
                "SmithyHTTPAPI",
                "SmithyTelemetryAPI",
            ]
        ),
        .target(
            name: "ClientRuntime",
            dependencies: [
                "Smithy",
                "SmithyTelemetryAPI",
                "SmithyHTTPClientAPI",
                "SmithyRetriesAPI",
                "SmithyRetries",
                "SmithyXML",
                "SmithyJSON",
                "SmithyFormURL",
                "SmithyIdentity",
                "SmithyIdentityAPI",
                "SmithyHTTPAPI",
                "SmithyHTTPClient",
                "SmithyHTTPAuth",
                "SmithyHTTPAuthAPI",
                "SmithyEventStreamsAPI",
                "SmithyEventStreams",
                "SmithyEventStreamsAuthAPI",
                "SmithyStreams",
                "SmithyChecksumsAPI",
                "SmithyChecksums",
                "SmithyCBOR",
                "SmithySerialization",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
            ],
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "SmithySwiftNIO",
            dependencies: [
                "Smithy",
                "SmithyHTTPAPI",
                "SmithyStreams",
                "SmithyHTTPClientAPI",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ],
            path: "Sources/SmithySwiftNIO"
        ),
        .target(
            name: "SmithyRetriesAPI"
        ),
        .target(
            name: "SmithyRetries",
            dependencies: ["SmithyRetriesAPI"]
        ),
        .target(
            name: "SmithyReadWrite",
            dependencies: ["Smithy", "SmithyTimestamps"]
        ),
        .target(
            name: "SmithyXML",
            dependencies: [
                "SmithySerialization",
                "SmithyReadWrite",
                "SmithyTimestamps",
                libXML2DependencyOrNil
            ].compactMap { $0 }
        ),
        .target(
            name: "SmithyJSON",
            dependencies: [
                "SmithySerialization",
                "SmithyReadWrite",
                "SmithyTimestamps"
            ]
        ),
        .target(
            name: "SmithyFormURL",
            dependencies: [
                "SmithyReadWrite",
                "SmithyTimestamps"
            ]
        ),
        libXML2TargetOrNil,
        .target(
            name: "SmithyTimestamps",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyTestUtil",
            dependencies: ["ClientRuntime", "SmithyHTTPAPI", "SmithyIdentity", "SmithyCBOR", "SmithyTelemetryAPI"]
        ),
        .target(
            name: "SmithyIdentity",
            dependencies: [
                "SmithyIdentityAPI",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .target(
            name: "SmithyIdentityAPI",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyHTTPAPI",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyHTTPClient",
            dependencies: [
                "Smithy",
                "SmithyHTTPAPI",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .target(
            name: "SmithyHTTPAuth",
            dependencies: [
                "Smithy",
                "SmithyHTTPAPI",
                "SmithyHTTPAuthAPI",
                "SmithyIdentity",
                "SmithyIdentityAPI",
                "SmithyChecksumsAPI",
                "SmithyHTTPClient",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .target(
            name: "SmithyHTTPAuthAPI",
            dependencies: ["Smithy", "SmithyHTTPAPI", "SmithyIdentityAPI"]
        ),
        .target(
            name: "SmithyEventStreamsAPI",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyEventStreamsAuthAPI",
            dependencies: ["Smithy", "SmithyEventStreamsAPI"]
        ),
        .target(
            name: "SmithyEventStreams",
            dependencies: [
                "Smithy",
                "SmithySerialization",
                "SmithyEventStreamsAPI",
                "SmithyEventStreamsAuthAPI",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .target(
            name: "SmithyStreams",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyChecksumsAPI",
            dependencies: ["Smithy"]
        ),
        .target(
            name: "SmithyChecksums",
            dependencies: [
                "Smithy",
                "SmithyChecksumsAPI",
                "SmithyStreams",
                "SmithyHTTPClient",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .target(
            name: "SmithyCBOR",
            dependencies: [
                "Smithy",
                "SmithySerialization",
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .target(
            name: "SmithyWaitersAPI"
        ),
        .plugin(
            name: "SmithyCodeGeneratorPlugin",
            capability: .buildTool(),
            dependencies: [
                "SmithyCodegenCLI",
            ]
        ),
        .executableTarget(
            name: "SmithyCodegenCLI",
            dependencies: [
                "SmithyCodegenCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "SmithyCodegenCore",
            dependencies: [
                "Smithy",
                "SmithySerialization",
            ],
            resources: [ .process("Resources") ]
        ),
        .target(
            name: "SmithyAWSJSON",
            dependencies: [
                "ClientRuntime",
                "Smithy",
                "SmithySerialization",
                "SmithyJSON",
                "SmithyEventStreams",
            ]
        ),
        .target(
            name: "SmithyRPCv2CBOR",
            dependencies: [
                "ClientRuntime",
                "Smithy",
                "SmithySerialization",
                "SmithyCBOR",
            ]
        ),
    ].compactMap { $0 }
}

var runtimeTestTargets: [PackageDescription.Target] {
    [.testTarget(name: "SmithySwiftTests")]
}
