package software.amazon.smithy.swift.codegen.traits

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.protocolspecificserde.xml.setupTests

class IdempotencyTokenTraitTests {
    @Test
    fun `generates idempotent middleware`() {
        val context = setupTests("Isolated/idempotencyToken.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/RestXmlProtocolClient.swift")
        val expectedContents = """
        builder.interceptors.add(ClientRuntime.IdempotencyTokenMiddleware<IdempotencyTokenWithStructureInput, IdempotencyTokenWithStructureOutput>(keyPath: \.token))
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
