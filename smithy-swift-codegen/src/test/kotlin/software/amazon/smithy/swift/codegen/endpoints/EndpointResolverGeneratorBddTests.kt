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

    @Test
    fun `flag off generates ruleSet resolver`() {
        val contents = render(model, useBddEndpoints = false)
        contents.shouldContain("try self.init(partitions: ClientRuntime.partitionJSON, ruleSet: Self.ruleSet)")
        contents.shouldNotContain("bytecode")
    }

    @Test
    fun `flag on generates bytecode resolver`() {
        val contents = render(model, useBddEndpoints = true, bddBytecoderPath = bytecoderPath)
        contents.shouldContain("bytecode: Foundation.Data(base64Encoded: Self.bytecode)!)")
        contents.shouldNotContain("ruleSet")

        val base64 = Regex("private static let bytecode = \"([^\"]+)\"").find(contents)!!.groupValues[1]
        val magic =
            Base64
                .getDecoder()
                .decode(base64)
                .copyOfRange(0, 4)
                .toString(Charsets.US_ASCII)
        assertEquals("RDPE", magic)
    }

    @Test
    fun `flag on without BDD trait falls back to ruleSet resolver`() {
        val noBddModel = "namespace com.test\nservice Example { version: \"1.0.0\" }".asSmithyModel()
        val contents = render(noBddModel, useBddEndpoints = true, bddBytecoderPath = bytecoderPath)
        contents.shouldContain("ruleSet: Self.ruleSet")
    }

    @Test
    fun `flag on without bytecoder path throws`() {
        assertThrows<CodegenException> { render(model, useBddEndpoints = true) }
    }

    private fun render(
        model: Model,
        useBddEndpoints: Boolean,
        bddBytecoderPath: String? = null,
    ): String {
        var settingsNode = getSettingsNode().withMember("useBddEndpoints", useBddEndpoints)
        bddBytecoderPath?.let { settingsNode = settingsNode.withMember("bddBytecoderPath", Node.from(it)) }
        val context = model.newTestContext(settings = SwiftSettings.from(model, settingsNode))
        EndpointResolverGenerator(ClientRuntimeTypes.Core.PartitionDefinition).render(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context.manifest.expectFileString("example/Sources/example/Endpoints.swift")
    }
}
