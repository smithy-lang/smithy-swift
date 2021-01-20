// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "ClientRuntime",
    platforms: [
	.macOS(.v10_15), 
	.iOS(.v13)
    ],
    products: [
        .library(name: "ClientRuntime", targets: ["ClientRuntime"]),
        .library(name: "SmithyTestUtil", targets: ["SmithyTestUtil"])
    ],
    dependencies: [
        .package(path: "~/work/smithy-swift/smithy-swift/Projects/Amplify/SwiftSDK/aws-crt-swift"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ClientRuntime",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "AwsCrt"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "ClientRuntimeTests",
            dependencies: ["ClientRuntime"]
        ),
        .target(
            name: "SmithyTestUtil",
            dependencies: ["ClientRuntime"]
        ),
        .testTarget(
            name: "SmithyTestUtilTests",
            dependencies: ["SmithyTestUtil"]
        )
    ]
)
