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
    private val location: String,
    private val localPath: String,
    override var packageName: String,
    private val distributionMethod: DistributionMethod,
) : Dependency {
    enum class DistributionMethod {
        SPR,
        GIT,
    }

    companion object {
        val NONE =
            SwiftDependency(
                "",
                "",
                "",
                "",
                "",
                "",
                DistributionMethod.GIT,
            )
        val SWIFT =
            SwiftDependency(
                "Swift",
                "",
                "",
                "",
                "",
                "",
                SwiftDependency.DistributionMethod.GIT,
            )
        val XCTest =
            SwiftDependency(
                "XCTest",
                null,
                "",
                "",
                "",
                "",
                DistributionMethod.GIT,
            )
        val CRT =
            SwiftDependency(
                "AwsCommonRuntimeKit",
                "swift6-support",
                "0.31.0",
                "https://github.com/awslabs/aws-crt-swift",
                "",
                "aws-crt-swift",
                DistributionMethod.GIT,
            )
        val CLIENT_RUNTIME = smithySwiftDependency("ClientRuntime")
        val SMITHY = smithySwiftDependency("Smithy")
        val SMITHY_IDENTITY_API = smithySwiftDependency("SmithyIdentityAPI")
        val SMITHY_IDENTITY = smithySwiftDependency("SmithyIdentity")
        val SMITHY_RETRIES_API = smithySwiftDependency("SmithyRetriesAPI")
        val SMITHY_RETRIES = smithySwiftDependency("SmithyRetries")
        val SMITHY_HTTP_API = smithySwiftDependency("SmithyHTTPAPI")
        val SMITHY_HTTP_AUTH_API = smithySwiftDependency("SmithyHTTPAuthAPI")
        val SMITHY_HTTP_AUTH = smithySwiftDependency("SmithyHTTPAuth")
        val SMITHY_CHECKSUMS_API = smithySwiftDependency("SmithyChecksumsAPI")
        val SMITHY_CHECKSUMS = smithySwiftDependency("SmithyChecksums")
        val SMITHY_STREAMS = smithySwiftDependency("SmithyStreams")
        val SMITHY_EVENT_STREAMS_API = smithySwiftDependency("SmithyEventStreamsAPI")
        val SMITHY_EVENT_STREAMS_AUTH_API = smithySwiftDependency("SmithyEventStreamsAuthAPI")
        val SMITHY_EVENT_STREAMS = smithySwiftDependency("SmithyEventStreams")
        val SMITHY_TEST_UTIL = smithySwiftDependency("SmithyTestUtil")
        val SMITHY_READ_WRITE = smithySwiftDependency("SmithyReadWrite")
        val SMITHY_TIMESTAMPS = smithySwiftDependency("SmithyTimestamps")
        val SMITHY_XML = smithySwiftDependency("SmithyXML")
        val SMITHY_JSON = smithySwiftDependency("SmithyJSON")
        val SMITHY_FORM_URL = smithySwiftDependency("SmithyFormURL")
        val SMITHY_WAITERS_API = smithySwiftDependency("SmithyWaitersAPI")
        val SMITHY_CBOR = smithySwiftDependency("SmithyCBOR")

        fun smithySwiftDependency(name: String): SwiftDependency =
            SwiftDependency(
                name,
                "main",
                "0.0.1",
                "https://github.com/smithy-lang/smithy-swift",
                "../../../smithy-swift",
                "smithy-swift",
                DistributionMethod.GIT,
            )
    }

    override fun getDependencies(): List<SymbolDependency> = listOf(toSymbolDependency())

    private fun toSymbolDependency(): SymbolDependency {
        val builder =
            SymbolDependency
                .builder()
                .putProperty("target", target)
                .putProperty("branch", branch)
                .putProperty("localPath", localPath)
                .packageName(packageName)
                .version(version)
        when (distributionMethod) {
            DistributionMethod.GIT -> {
                builder.putProperty("url", location)
            }
            DistributionMethod.SPR -> {
                builder.putProperty("scope", location)
            }
        }
        return builder.build()
    }
}
