/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.swift.codegen.resources.Resources

enum class SwiftDependency(
    override val target: String,
    private val branch: String? = null,
    private val version: String,
    private val url: String,
    private val localPath: String,
    override var packageName: String
) : Dependency {
    BIG("ComplexModule", null, "0.0.5", "https://github.com/apple/swift-numerics", "", "swift-numerics"),
    SWIFT_LOG("Logging", null, "", "", "", ""),
    CLIENT_RUNTIME(
        "ClientRuntime",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
    ),
    SMITHY_RETRIES_API(
        "SmithyRetriesAPI",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
    ),
    SMITHY_RETRIES(
        "SmithyRetries",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
    ),
    XCTest("XCTest", null, "", "", "", ""),
    SMITHY_TEST_UTIL(
        "SmithyTestUtil",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
    ),
    SMITHY_READ_WRITE(
        "SmithyReadWrite",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
    ),
    SMITHY_XML(
        "SmithyXML",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
    ),
    SMITHY_JSON(
        "SmithyJSON",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
    ),
    SMITHY_FORM_URL(
        "SmithyFormURL",
        "main",
        "0.1.0",
        "https://github.com/smithy-lang/smithy-swift",
        Resources.computeAbsolutePath("smithy-swift", "", "SMITHY_SWIFT_CI_DIR"),
        "smithy-swift"
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
