// swift-tools-version:5.3
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
        .package(name: "AwsCrt", url: "https://github.com/awslabs/aws-crt-swift", .branch("master")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
        targets: [
        .target(
            name: "ClientRuntime",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "AwsCrt"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "./Packages/ClientRuntime/Sources"
        ),
        .testTarget(
            name: "ClientRuntimeTests",
            dependencies: [
	        "ClientRuntime",
	        "SmithyTestUtil"
	    ],
	    path: "./Packages/ClientRuntime/Tests"
        ),
        .target(
            name: "SmithyTestUtil",
            dependencies: ["ClientRuntime"],
            path: "./Packages/SmithyTestUtil/Sources"
        ),
        .testTarget(
            name: "SmithyTestUtilTests",
            dependencies: ["SmithyTestUtil"],
            path: "./Packages/SmithyTestUtil/Tests"
        )
    ]
)

