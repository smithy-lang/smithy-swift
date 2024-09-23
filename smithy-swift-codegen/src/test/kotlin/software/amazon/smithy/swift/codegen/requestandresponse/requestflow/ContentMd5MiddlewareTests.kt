package software.amazon.smithy.swift.codegen.requestandresponse.requestflow

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.protocolspecificserde.xml.setupTests

class ContentMd5MiddlewareTests {
    @Test
    fun `generates ContentMD5 middleware`() {
        val context = setupTests("Isolated/contentmd5checksum.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/RestXmlProtocolClient.swift")
        val expectedContents = """
        builder.interceptors.add(ClientRuntime.ContentMD5Middleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>())
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
