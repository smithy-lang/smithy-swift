// swift-tools-version:5.4

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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
        .library(name: "JSONRuntime", targets: ["JSONRuntime"]),
        .library(name: "XMLRuntime", targets: ["XMLRuntime"]),
        .library(name: "SmithyTestUtil", targets: ["SmithyTestUtil"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.13.0")
    ],
    targets: [
        .target(
            name: "Runtime",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "AwsCrt"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "./Runtime/Sources",
            exclude: excludes
        ),
        .testTarget(
            name: "RuntimeTests",
            dependencies: [
                "Runtime",
                "SmithyTestUtil"
            ],
            path: "./Runtime/Tests"
        ),
        .target(
            name: "JSONRuntime",
            dependencies: [
                "Runtime"
            ],
            path: "./JSONRuntime/Sources",
            exclude: excludes
        ),
        .testTarget(
            name: "JSONRuntimeTests",
            dependencies: [
                "Runtime",
                "SmithyTestUtil"
            ],
            path: "./JSONRuntime/Tests"
        ),
        .target(
            name: "XMLRuntime",
            dependencies: [
                "Runtime",
                .product(name: "XMLCoder", package: "XMLCoder")
            ],
            path: "./XMLRuntime/Sources",
            exclude: excludes
        ),
        .testTarget(
            name: "XMLRuntimeTests",
            dependencies: [
                "Runtime",
                "SmithyTestUtil"
            ],
            path: "./XMLRuntime/Tests"
        ),
        .target(
            name: "SmithyTestUtil",
            dependencies: ["Runtime", "JSONRuntime", "XMLRuntime"],
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
