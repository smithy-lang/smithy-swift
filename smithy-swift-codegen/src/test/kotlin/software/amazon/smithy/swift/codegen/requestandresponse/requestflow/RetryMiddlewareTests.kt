package software.amazon.smithy.swift.codegen.requestandresponse.requestflow

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.protocolspecificserde.xml.setupTests

class RetryMiddlewareTests {
    @Test
    fun `generates operation with retry middleware`() {
        val context = setupTests("Isolated/contentmd5checksum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/RestXmlProtocolClient.swift")
        val expectedContents = """
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(ClientRuntime.DefaultRetryErrorInfoProvider.errorInfo(for:))
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
