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
    targets: [
        .target(
            name: "ClientRuntime",
            path: "./ClientRuntime"
        ),
        .testTarget(
            name: "ClientRuntimeTests",
            dependencies: ["ClientRuntime"],
            path: "./ClientRuntimeTests"
        ),
        .target(
            name: "SmithyTestUtil",
            dependencies: ["ClientRuntime"],
            path: "./SmithyTestUtil"
        ),
        .testTarget(
            name: "SmithyTestUtilTests",
            dependencies: ["SmithyTestUtil"],
            path: "./SmithyTestUtilTests"
        )
    ]
)
