package software.amazon.smithy.swift.codegen.codegencomponents

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.swift.codegen.DefaultClientConfigurationIntegration
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.getSettingsNode
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPRestJsonProtocolGenerator
import software.amazon.smithy.swift.codegen.shouldSyntacticSanityCheck

class UnionCustomDebugStringConvertibleGeneratorTests {
    private val smithyFile = "union-custom-debug-string-convertible-test.smithy"
    private val serviceShapeId = "com.test#Example"
    private val modelsPath = "RestJson/Sources/RestJson/models"

    @Test
    fun `union with sensitive variants redacts only the sensitive variants`() {
        val context = setupTests()
        val contents = getFileContents(context.manifest, "$modelsPath/SensitiveVariantUnion+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        val expected = """
extension ExampleClientTypes.SensitiveVariantUnion: Swift.CustomDebugStringConvertible {
    public var debugDescription: Swift.String {
        switch self {
        case .plain(let value):
            return "SensitiveVariantUnion.plain(\(Swift.String(describing: value)))"
        case .secret:
            return "SensitiveVariantUnion.secret(\"CONTENT_REDACTED\")"
        case .secretlist:
            return "SensitiveVariantUnion.secretlist(\"CONTENT_REDACTED\")"
        case .secretmap:
            return "SensitiveVariantUnion.secretmap(\"CONTENT_REDACTED\")"
        case .withstruct(let value):
            return "SensitiveVariantUnion.withstruct(\(Swift.String(describing: value)))"
        case .sdkUnknown(let value):
            return "SensitiveVariantUnion.sdkUnknown(\(Swift.String(describing: value)))"
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `structure held by a union variant keeps its own redaction`() {
        val context = setupTests()
        val contents = getFileContents(context.manifest, "$modelsPath/StructWithSensitiveMember+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("password: \\\"CONTENT_REDACTED\\\"")
    }

    @Test
    fun `union with sensitive trait is fully redacted`() {
        val context = setupTests()
        val contents = getFileContents(context.manifest, "$modelsPath/SensitiveUnion+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        val expected = """
extension ExampleClientTypes.SensitiveUnion: Swift.CustomDebugStringConvertible {
    public var debugDescription: Swift.String {
        "CONTENT_REDACTED"
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `unions nested in a list, a map and a structure are redacted`() {
        val context = setupTests()
        for (name in listOf("ListedUnion", "MappedUnion", "HeldUnion")) {
            val contents = getFileContents(context.manifest, "$modelsPath/$name+CustomDebugStringConvertible.swift")
            contents.shouldSyntacticSanityCheck()
            contents.shouldContainOnlyOnce("extension ExampleClientTypes.$name: Swift.CustomDebugStringConvertible {")
            contents.shouldContainOnlyOnce("case .secret:")
            contents.shouldContainOnlyOnce("return \"$name.secret(\\\"CONTENT_REDACTED\\\")\"")
            contents.shouldContainOnlyOnce("case .plain(let value):")
        }
    }

    @Test
    fun `union variant targeting a sensitive union is redacted`() {
        val context = setupTests()
        val contents = getFileContents(context.manifest, "$modelsPath/ContentBlockDelta+CustomDebugStringConvertible.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("case .reasoningcontent:")
        contents.shouldContainOnlyOnce("return \"ContentBlockDelta.reasoningcontent(\\\"CONTENT_REDACTED\\\")\"")
        contents.shouldContainOnlyOnce("case .text(let value):")

        val nested = getFileContents(context.manifest, "$modelsPath/ReasoningContentBlockDelta+CustomDebugStringConvertible.swift")
        nested.shouldSyntacticSanityCheck()
        nested.shouldContainOnlyOnce("\"CONTENT_REDACTED\"")
    }

    @Test
    fun `union without sensitive content gets no debug description extension`() {
        val context = setupTests()
        context.manifest.hasFile("$modelsPath/PlainUnion.swift") shouldBe true
        context.manifest.hasFile("$modelsPath/PlainUnion+CustomDebugStringConvertible.swift") shouldBe false
    }

    @Test
    fun `union gets no debug description extension in schema-based mode`() {
        val model =
            Model
                .assembler()
                .addImport(javaClass.classLoader.getResource(smithyFile))
                .discoverModels()
                .assemble()
                .unwrap()
        val settingsNode =
            getSettingsNode(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol")
                .toBuilder()
                .withMember(SwiftSettings.FORCE_SCHEMA_BASED, Node.from(true))
                .build()
        val manifest = MockManifest()
        val pluginContext =
            PluginContext
                .builder()
                .model(model)
                .fileManifest(manifest)
                .settings(settingsNode)
                .build()
        SwiftCodegenPlugin().execute(pluginContext)

        manifest.hasFile("$modelsPath/SensitiveVariantUnion.swift") shouldBe true
        manifest.hasFile("$modelsPath/SensitiveVariantUnion+CustomDebugStringConvertible.swift") shouldBe false
        manifest.hasFile("$modelsPath/SensitiveUnion+CustomDebugStringConvertible.swift") shouldBe false
    }

    private fun setupTests(): TestContext {
        val context =
            TestContext.initContextFrom(
                listOf(smithyFile),
                serviceShapeId,
                MockHTTPRestJsonProtocolGenerator(),
                { model -> model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol") },
                listOf(DefaultClientConfigurationIntegration()),
            )

        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
