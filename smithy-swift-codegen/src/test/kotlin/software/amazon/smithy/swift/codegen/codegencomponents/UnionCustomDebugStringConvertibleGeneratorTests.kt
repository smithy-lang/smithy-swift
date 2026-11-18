package software.amazon.smithy.swift.codegen.codegencomponents

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.shouldBe
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
import software.amazon.smithy.swift.codegen.getSettingsNode
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPRestJsonProtocolGenerator

class UnionCustomDebugStringConvertibleGeneratorTests {
    private val smithyFile = "union-custom-debug-string-convertible-test.smithy"
    private val serviceShapeId = "com.test#Example"
    private val modelsPath = "RestJson/Sources/RestJson/models"

    // Behavior of the generated debugDescription is tested in Swift, in test-sdks/Tests/UnionDebugDescriptionTests.

    @Test
    fun `union with sensitive content gets a debug description extension`() {
        val context = setupTests()
        for (name in listOf("SensitiveVariantUnion", "SensitiveUnion", "ListedUnion", "MappedUnion", "HeldUnion", "ContentBlockDelta")) {
            context.manifest.hasFile("$modelsPath/$name+CustomDebugStringConvertible.swift") shouldBe true
        }
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
