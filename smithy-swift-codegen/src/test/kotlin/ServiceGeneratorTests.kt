/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.swift.codegen.AddOperationShapes
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftWriter

class ServiceGeneratorTests {

    private val commonTestContents: String

    init {
        var model = javaClass.getResource("service-generator-test-operations.smithy").asSmithy()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example", "Example")
        val writer = SwiftWriter("test")

        val settings = model.defaultSettings()
        val manifest = MockManifest()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val writers = SwiftDelegator(settings, model, manifest, provider)
        val generator = ServiceGenerator(settings, model, provider, writer, writers)
        generator.render()

        commonTestContents = writer.toString()
    }

    @Test
    fun `it renders swift protocols in separate file`() {
        val model = javaClass.getResource("service-generator-test-operations.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)

        SwiftCodegenPlugin().execute(context)

        Assertions.assertTrue(manifest.hasFile("example/ExampleClientProtocol.swift"))
    }

    @Test
    fun `it has header`() {
        commonTestContents.shouldContain(SwiftWriter.staticHeader)
    }

    @Test
    fun `it has swift protocol signature`() {
        commonTestContents.shouldContainOnlyOnce("public protocol ExampleClientProtocol {")
    }

    @Test
    fun `it has dependency on client runtime`() {
        commonTestContents.shouldContainOnlyOnce("import ClientRuntime")
    }

    @Test
    fun `it renders swift func signatures correctly`() {
        val expectedSignatures = listOf(
            "func getFooStreamingInput(input: GetFooStreamingInputInput, streamSource: StreamSource, completion: @escaping (SdkResult<GetFooStreamingInputOutput, GetFooStreamingInputError>) -> Void)",
            "func getFooNoOutput(input: GetFooNoOutputInput, completion: @escaping (SdkResult<GetFooNoOutputOutput, GetFooNoOutputError>) -> Void)",
            "func getFooStreamingOutput(input: GetFooStreamingOutputInput, streamSink: StreamSink, completion: @escaping (SdkResult<GetFooStreamingOutputOutput, GetFooStreamingOutputError>) -> Void)",
            "func getFoo(input: GetFooInput, completion: @escaping (SdkResult<GetFooOutput, GetFooError>) -> Void)",
            "func getFooNoInput(input: GetFooNoInputInput, completion: @escaping (SdkResult<GetFooNoInputOutput, GetFooNoInputError>) -> Void)",
            "func getFooStreamingInputNoOutput(input: GetFooStreamingInputNoOutputInput, streamSource: StreamSource, completion: @escaping (SdkResult<GetFooStreamingInputNoOutputOutput, GetFooStreamingInputNoOutputError>) -> Void)",
            "func getFooStreamingOutputNoInput(input: GetFooStreamingOutputNoInputInput, streamSink: StreamSink, completion: @escaping (SdkResult<GetFooStreamingOutputNoInputOutput, GetFooStreamingOutputNoInputError>) -> Void)"
        )
        expectedSignatures.forEach {
            commonTestContents.shouldContainOnlyOnce(it)
        }
    }

    @Test
    fun `it syntactic sanity checks`() {
        // sanity check since we are testing fragments
        var openBraces = 0
        var closedBraces = 0
        var openParens = 0
        var closedParens = 0
        commonTestContents.forEach {
            when (it) {
                '{' -> openBraces++
                '}' -> closedBraces++
                '(' -> openParens++
                ')' -> closedParens++
            }
        }
        Assertions.assertEquals(openBraces, closedBraces)
        Assertions.assertEquals(openParens, closedParens)
    }
}
