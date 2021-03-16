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
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ClientRuntime",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "AwsCrt"),
                .product(name: "Logging", package: "swift-log")
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

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(name: "AwsCrt", url: "https://github.com/awslabs/aws-crt-swift", .branch(relatedDependenciesBranch)),
    ]
} else {
    package.dependencies += [
        .package(name: "AwsCrt", path: "./target/build/deps/"),
    ]
}
