/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.endpoints

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldNotContain
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.asSmithyModel
import software.amazon.smithy.swift.codegen.getSettingsNode
import software.amazon.smithy.swift.codegen.newTestContext
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import java.io.File
import java.util.Base64

class EndpointResolverGeneratorBddTests {
    private val bddTraitJson = javaClass.getResource("/simple-endpoint-bdd.json")!!.readText()
    private val bytecoderPath = File(javaClass.getResource("/bdd-bytecoder.py")!!.toURI()).absolutePath

    private val model =
        """
        namespace com.test
        use smithy.rules#clientContextParams
        use smithy.rules#endpointBdd

        @clientContextParams(
            Region: { type: "string", documentation: "The region" }
            Endpoint: { type: "string", documentation: "The endpoint" }
        )
        @endpointBdd($bddTraitJson)
        service Example { version: "1.0.0" }
        """.asSmithyModel()

    private val ruleSetJson =
        """
        {
          "version": "1.0",
          "parameters": {
            "Region": { "type": "string", "required": true, "documentation": "The AWS region" },
            "Endpoint": { "type": "string", "required": false, "documentation": "Override the endpoint URL" }
          },
          "rules": [
            { "type": "endpoint", "conditions": [], "endpoint": { "url": "https://example.com" } }
          ]
        }
        """

    private val bothTraitsModel =
        """
        namespace com.test
        use smithy.rules#clientContextParams
        use smithy.rules#endpointBdd
        use smithy.rules#endpointRuleSet

        @clientContextParams(
            Region: { type: "string", documentation: "The region" }
            Endpoint: { type: "string", documentation: "The endpoint" }
        )
        @endpointRuleSet($ruleSetJson)
        @endpointBdd($bddTraitJson)
        service Example { version: "1.0.0" }
        """.asSmithyModel()

    @Test
    fun `model with both traits generates bytecode resolver`() {
        val contents = render(bothTraitsModel, bddBytecoderPath = bytecoderPath)
        contents.shouldContain("private static let bytecode = Foundation.Data(base64Encoded: \"")
        contents.shouldContain("try self.init(partitions: ClientRuntime.partitionJSON, bytecode: Self.bytecode)")
        contents.shouldNotContain("ruleSet")
    }

    @Test
    fun `BDD-only model generates bytecode resolver`() {
        val contents = render(model, bddBytecoderPath = bytecoderPath)
        contents.shouldContain("private static let bytecode = Foundation.Data(base64Encoded: \"")
        contents.shouldContain("try self.init(partitions: ClientRuntime.partitionJSON, bytecode: Self.bytecode)")
        contents.shouldNotContain("ruleSet")

        val base64 =
            Regex("private static let bytecode = Foundation\\.Data\\(base64Encoded: \"([^\"]+)\"\\)!")
                .find(contents)!!
                .groupValues[1]
        val magic =
            Base64
                .getDecoder()
                .decode(base64)
                .copyOfRange(0, 4)
                .toString(Charsets.US_ASCII)
        assertEquals("RDPE", magic)
    }

    @Test
    fun `EndpointParams is generated from the BDD trait for a BDD-only model`() {
        val context = model.newTestContext(settings = SwiftSettings.from(model, getSettingsNode()))
        EndpointParamsGenerator(context.generationCtx).render()
        context.generationCtx.delegator.flushWriters()
        val contents = context.manifest.expectFileString("example/Sources/example/Endpoints.swift")
        contents.shouldContain("public let region: Swift.String")
        contents.shouldContain("public let endpoint: Swift.String?")
        contents.shouldContain("try context.add(name: \"Region\", value: self.region)")
    }

    @Test
    fun `model without BDD trait generates ruleSet resolver without a bytecoder path`() {
        val noBddModel = "namespace com.test\nservice Example { version: \"1.0.0\" }".asSmithyModel()
        val contents = render(noBddModel)
        contents.shouldContain("ruleSet: Self.ruleSet")
        contents.shouldNotContain("bytecode")
    }

    @Test
    fun `BDD trait without bytecoder path throws`() {
        assertThrows<CodegenException> { render(model) }
    }

    private fun render(
        model: Model,
        bddBytecoderPath: String? = null,
    ): String {
        var settingsNode = getSettingsNode()
        bddBytecoderPath?.let { settingsNode = settingsNode.withMember("bddBytecoderPath", Node.from(it)) }
        val context = model.newTestContext(settings = SwiftSettings.from(model, settingsNode))
        EndpointResolverGenerator(ClientRuntimeTypes.Core.PartitionDefinition).render(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context.manifest.expectFileString("example/Sources/example/Endpoints.swift")
    }
}
