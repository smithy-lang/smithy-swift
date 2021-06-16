/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolDependencyContainer
import software.amazon.smithy.swift.codegen.resources.Resources

enum class SwiftDependency(
    val target: String,
    private val branch: String? = null,
    val version: String,
    private val url: String,
    private val localPath: String,
    var packageName: String
) : SymbolDependencyContainer {
    BIG("ComplexModule", null, "0.0.5", "https://github.com/apple/swift-numerics", "", "swift-numerics"),
    CLIENT_RUNTIME(
        "ClientRuntime",
        "master",
        "0.1.0",
        "https://github.com/awslabs/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift/Packages", "Packages", "SMITHY_SWIFT_CI_DIR") + "/Packages",
        "ClientRuntime"
    ),
    XCTest("XCTest", null, "", "", "", ""),
    SMITHY_TEST_UTIL(
        "SmithyTestUtil",
        "master",
        "0.1.0",
        "https://github.com/awslabs/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift/Packages", "Packages", "SMITHY_SWIFT_CI_DIR") + "/Packages",
        "ClientRuntime"
    );

    override fun getDependencies(): List<SymbolDependency> {
        val dependency = SymbolDependency.builder()
            .putProperty("target", target)
            .putProperty("branch", branch)
            .putProperty("localPath", localPath)
            .packageName(packageName)
            .version(version)
            .putProperty("url", url)
            .build()
        return listOf(dependency)
    }
}
