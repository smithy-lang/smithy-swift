package software.amazon.smithy.swift.codegen.requestandresponse.requestflow

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldNotContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.protocols.rpcv2cbor.RpcV2CborProtocolGenerator

class Rpcv2CborWithHttpQueryOnInputTests {
    @Test
    fun `does not emit queryItemProvider middleware for rpcv2Cbor service with @httpQuery member traits`() {
        val context = setupTests("rpcv2cbor-with-httpquery-on-input.smithy", "com.test#Example")
        val client = getFileContents(context.manifest, "example/Sources/example/ExampleClient.swift")
        client.shouldNotContain("ListEvaluatorsInput.queryItemProvider(_:)")
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context =
            TestContext.initContextFrom(
                smithyFile,
                serviceShapeId,
                RpcV2CborProtocolGenerator(),
                { model -> model.defaultSettings(serviceShapeId, "example", "1.0.0", "Example") },
            )
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateDeserializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
