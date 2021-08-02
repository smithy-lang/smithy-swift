// swift-tools-version:5.4
import PackageDescription
import class Foundation.ProcessInfo

let excludes = ["README.md"]

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
            path: "./ClientRuntime/Sources",
            exclude: excludes
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

if let crtDir = ProcessInfo.processInfo.environment["AWS_CRT_SWIFT_CI_DIR"] {
    package.dependencies += [
        .package(name: "AwsCrt", path: "\(crtDir)")
    ]
} else {
    package.dependencies += [
        .package(name: "AwsCrt", path: "~/Projects/Amplify/SwiftSDK/aws-crt-swift")
    ]
}
