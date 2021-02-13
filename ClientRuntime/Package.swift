// swift-tools-version:5.3
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
        .package(name: "AwsCrt", path: "~/Projects/Amplify/SwiftSDK/aws-crt-swift"),
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
            dependencies: [
	        "ClientRuntime",
	        "SmithyTestUtil"
	    ]
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
