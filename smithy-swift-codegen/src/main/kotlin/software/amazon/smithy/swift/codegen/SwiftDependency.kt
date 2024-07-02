/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.SymbolDependency

class SwiftDependency(
    override val target: String,
    private val branch: String? = null,
    private val version: String,
    private val url: String,
    private val localPath: String,
    override var packageName: String,
) : Dependency {

    companion object {
        val NONE = SwiftDependency("", "", "", "", "", "")
        val XCTest = SwiftDependency("XCTest", null, "", "", "", "")
        val CRT = SwiftDependency(
            "AwsCommonRuntimeKit",
            null,
            "0.30.0",
            "https://github.com/awslabs/aws-crt-swift",
            "",
            "aws-crt-swift",
        )
        val CLIENT_RUNTIME = SwiftDependency(
            "ClientRuntime",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY = SwiftDependency(
            "Smithy",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_IDENTITY_API = SwiftDependency(
            "SmithyIdentityAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_IDENTITY = SwiftDependency(
            "SmithyIdentity",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_RETRIES_API = SwiftDependency(
            "SmithyRetriesAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_RETRIES = SwiftDependency(
            "SmithyRetries",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_HTTP_API = SwiftDependency(
            "SmithyHTTPAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_HTTP_AUTH_API = SwiftDependency(
            "SmithyHTTPAuthAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_CHECKSUMS_API = SwiftDependency(
            "SmithyChecksumsAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_CHECKSUMS = SwiftDependency(
            "SmithyChecksums",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_STREAMS = SwiftDependency(
            "SmithyStreams",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_EVENT_STREAMS_API = SwiftDependency(
            "SmithyEventStreamsAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_EVENT_STREAMS_AUTH_API = SwiftDependency(
            "SmithyEventStreamsAuthAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_EVENT_STREAMS = SwiftDependency(
            "SmithyEventStreams",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_TEST_UTIL = SwiftDependency(
            "SmithyTestUtil",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_READ_WRITE = SwiftDependency(
            "SmithyReadWrite",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_TIMESTAMPS = SwiftDependency(
            "SmithyTimestamps",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_XML = SwiftDependency(
            "SmithyXML",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_JSON = SwiftDependency(
            "SmithyJSON",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_FORM_URL = SwiftDependency(
            "SmithyFormURL",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
        val SMITHY_WAITERS_API = SwiftDependency(
            "SmithyWaitersAPI",
            "main",
            "0.1.0",
            "https://github.com/smithy-lang/smithy-swift.git",
            "../../../smithy-swift",
            "smithy-swift",
        )
    }

    override fun getDependencies(): List<SymbolDependency> {
        return listOf(toSymbolDependency())
    }

    private fun toSymbolDependency(): SymbolDependency {
        return SymbolDependency.builder()
            .putProperty("target", target)
            .putProperty("branch", branch)
            .putProperty("localPath", localPath)
            .packageName(packageName)
            .version(version)
            .putProperty("url", url)
            .build()
    }
}
