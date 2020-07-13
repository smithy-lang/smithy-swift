// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "ClientRuntime",
    platforms: [
	.macOS(.v10_15), 
	.iOS(.v13)
    ],
    products: [
        .library(name: "ClientRuntime", targets: ["ClientRuntime"])
    ],
    targets: [
        .target(
            name: "ClientRuntime",
            path: "./ClientRuntime"
        ),
        .testTarget(
            name: "ClientRuntimeTests",
            path: "./ClientRuntimeTests"
        )
    ]
)
