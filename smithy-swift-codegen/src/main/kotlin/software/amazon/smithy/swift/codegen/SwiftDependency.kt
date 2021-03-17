/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolDependencyContainer
import software.amazon.smithy.swift.codegen.resources.Resources

enum class SwiftDependency(val type: String, val target: String, val branch: String? = null, val version: String, val url: String, var packageName: String) : SymbolDependencyContainer {
    // Note: "namespace" is sub module in the full library "packageName". We use the namespace to minimize the module import. But, the entire package is "packageName"
    BIG("", "ComplexModule", null, "0.0.5", "https://github.com/apple/swift-numerics", "swift-numerics"),
    CLIENT_RUNTIME(
        "",
        "ClientRuntime",
        null,
        "0.1.0",
        Resources.computeAbsolutePath("smithy-swift/Packages", "SMITHY_SWIFT_CI_DIR"),
        "ClientRuntime"
    ),
    XCTest("", "XCTest", null, "", "", ""),
    SMITHY_TEST_UTIL(
        "",
        "SmithyTestUtil",
        null,
        "0.1.0",
        Resources.computeAbsolutePath("smithy-swift/Packages", "SMITHY_SWIFT_CI_DIR"),
        "ClientRuntime"
    );

    override fun getDependencies(): List<SymbolDependency> {
        val dependency = SymbolDependency.builder()
            .dependencyType(type)
            .putProperty("target", target)
            .putProperty("branch", branch)
            .packageName(packageName)
            .version(version)
            .putProperty("url", url)
            .build()
        return listOf(dependency)
    }
}
