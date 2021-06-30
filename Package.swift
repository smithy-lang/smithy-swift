// swift-tools-version:5.4
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
        .package(name: "AwsCrt", url: "https://github.com/awslabs/aws-crt-swift.git", from: "1.0.0"),
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
