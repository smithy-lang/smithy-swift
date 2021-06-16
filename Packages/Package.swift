// swift-tools-version:5.4
import PackageDescription
import class Foundation.ProcessInfo

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
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "ClientRuntime",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "AwsCrt"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "XMLCoder", package: "XMLCoder")
            ],
            path: "./ClientRuntime/Sources"
        ),
        .testTarget(
            name: "ClientRuntimeTests",
            dependencies: [
	        "ClientRuntime",
	        "SmithyTestUtil"
	    ],
	    path: "./ClientRuntime/Tests"
        ),
        .target(
            name: "SmithyTestUtil",
            dependencies: ["ClientRuntime"],
            path: "./SmithyTestUtil/Sources"
        ),
        .testTarget(
            name: "SmithyTestUtilTests",
            dependencies: ["SmithyTestUtil"],
            path: "./SmithyTestUtil/Tests"
        )
    ]
)

let relatedDependenciesBranch = "master"
if ProcessInfo.processInfo.environment["AWS_SDK_SWIFT_CI_DIR"] != nil {
    package.dependencies += [
        .package(name: "AwsCrt", url: "https://github.com/awslabs/aws-crt-swift", .branch(relatedDependenciesBranch))
    ]
} else {
    package.dependencies += [
        .package(name: "AwsCrt", path: "~/Projects/Amplify/SwiftSDK/aws-crt-swift")
    ]
}

