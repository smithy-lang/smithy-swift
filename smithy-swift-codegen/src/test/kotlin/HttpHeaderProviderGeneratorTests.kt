/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpHeaderProviderGeneratorTests {
    private var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    var newTestContext: TestContext
    init {
        newTestContext = newTestContext()
        newTestContext.generator.generateSerializers(newTestContext.generationCtx)
        newTestContext.generator.generateProtocolClient(newTestContext.generationCtx)
        newTestContext.generator.generateDeserializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test request builder`() {
        val contents = getModelFileContents("Sources/example", "SmokeTestInput+HeaderProvider.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension SmokeTestInput {

    static func headerProvider(_ value: SmokeTestInput) -> SmithyHTTPAPI.Headers {
        var items = SmithyHTTPAPI.Headers()
        if let header1 = value.header1 {
            items.add(SmithyHTTPAPI.Header(name: "X-Header1", value: Swift.String(header1)))
        }
        if let header2 = value.header2 {
            items.add(SmithyHTTPAPI.Header(name: "X-Header2", value: Swift.String(header2)))
        }
        return items
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds headers with enums as raw values`() {
        val contents = getModelFileContents("Sources/example", "EnumInputInput+HeaderProvider.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension EnumInputInput {

    static func headerProvider(_ value: EnumInputInput) -> SmithyHTTPAPI.Headers {
        var items = SmithyHTTPAPI.Headers()
        if let enumHeader = value.enumHeader {
            items.add(SmithyHTTPAPI.Header(name: "X-EnumHeader", value: Swift.String(enumHeader.rawValue)))
        }
        return items
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds header with idempotency token value`() {
        val contents = getModelFileContents(
            "Sources/example",
            "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput+HeaderProvider.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput {

    static func headerProvider(_ value: IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput) -> SmithyHTTPAPI.Headers {
        var items = SmithyHTTPAPI.Headers()
        if let token = value.token {
            items.add(SmithyHTTPAPI.Header(name: "token", value: Swift.String(token)))
        }
        return items
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates http headers for timestamps with format`() {
        val contents =
            getModelFileContents("Sources/example", "TimestampInputInput+HeaderProvider.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension TimestampInputInput {

    static func headerProvider(_ value: TimestampInputInput) -> SmithyHTTPAPI.Headers {
        var items = SmithyHTTPAPI.Headers()
        if let headerEpoch = value.headerEpoch {
            items.add(SmithyHTTPAPI.Header(name: "X-Epoch", value: Swift.String(SmithyTimestamps.TimestampFormatter(format: .epochSeconds).string(from: headerEpoch))))
        }
        if let headerHttpDate = value.headerHttpDate {
            items.add(SmithyHTTPAPI.Header(name: "X-Date", value: Swift.String(SmithyTimestamps.TimestampFormatter(format: .httpDate).string(from: headerHttpDate))))
        }
        return items
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }
}
