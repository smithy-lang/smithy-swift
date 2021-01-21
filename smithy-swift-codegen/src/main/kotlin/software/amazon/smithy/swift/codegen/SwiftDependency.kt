/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolDependencyContainer
import java.io.File

enum class SwiftDependency(val type: String, val namespace: String, val version: String, val url: String, var packageName: String) : SymbolDependencyContainer {
    // Note: "namespace" is sub module in the full library "packageName". We use the namespace to minimize the module import. But, the entire package is "packageName"
    BIG("", "ComplexModule", "0.0.5", "https://github.com/apple/swift-numerics", packageName = "swift-numerics"),
    CLIENT_RUNTIME(
        "",
        "ClientRuntime",
        "0.1.0",
        computeAbsolutePath("smithy-swift/ClientRuntime"),
        "ClientRuntime"
    ),
    XCTest("", "XCTest", "", "", ""),
    SMITHY_TEST_UTIL(
        "",
        "SmithyTestUtil",
        "0.1.0",
        computeAbsolutePath("smithy-swift/ClientRuntime"),
        "ClientRuntime");

    override fun getDependencies(): List<SymbolDependency> {
        val dependency = SymbolDependency.builder()
            .dependencyType(type)
            .packageName(namespace)
            .version(version)
            .putProperty("url", url)
            .putProperty("swiftPackageName", packageName)
            .build()
        return listOf(dependency)
    }
}

private fun computeAbsolutePath(relativePath: String): String {
    var userDirPath = System.getProperty("user.dir")
    while (userDirPath.isNotEmpty()) {
        val fileName = userDirPath.removeSuffix("/") + "/" + relativePath
        val file = File(fileName)
        if (file.isDirectory) {
            return fileName
        }
        userDirPath = userDirPath.substring(0, userDirPath.length-1)
    }
    return ""
}