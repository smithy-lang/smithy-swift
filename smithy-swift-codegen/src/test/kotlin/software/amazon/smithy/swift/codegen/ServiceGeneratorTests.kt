/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
 */

package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider

class ServiceGeneratorTests : TestsBase() {

    private val commonTestContents: String

    init {
        var model = createModelFromSmithy("service-generator-test-operations.smithy")

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val writer = SwiftWriter("test")

        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)

        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val writers = SwiftDelegator(settings, model, manifest, provider)
        val generator = ServiceGenerator(settings, model, provider, writer, writers)
        generator.render()

        commonTestContents = writer.toString()
    }

    @Test
    fun `it renders swift protocols in separate file`() {
        val model = createModelFromSmithy("recursive-shape-test.smithy")
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
                "func getFooStreamingInput(input: GetFooStreamingRequest, completion: @escaping (SdkResult<GetFooResponse, GetFooStreamingInputError>) -> Void)",
                "func getFooNoOutput(input: GetFooRequest, completion: @escaping (SdkResult<GetFooNoOutputOutput, GetFooNoOutputError>) -> Void)",
                "func getFooStreamingOutput(input: GetFooRequest, streamingHandler: StreamingProvider, completion: @escaping (SdkResult<GetFooStreamingResponse, GetFooStreamingOutputError>) -> Void)",
                "func getFoo(input: GetFooRequest, completion: @escaping (SdkResult<GetFooResponse, GetFooError>) -> Void)",
                "func getFooNoInput(input: GetFooNoInputInput, completion: @escaping (SdkResult<GetFooResponse, GetFooNoInputError>) -> Void)",
                "func getFooStreamingInputNoOutput(input: GetFooStreamingRequest, completion: @escaping (SdkResult<GetFooStreamingInputNoOutputOutput, GetFooStreamingInputNoOutputError>) -> Void)",
                "func getFooStreamingOutputNoInput(input: GetFooStreamingOutputNoInputInput, streamingHandler: StreamingProvider, completion: @escaping (SdkResult<GetFooStreamingResponse, GetFooStreamingOutputNoInputError>) -> Void)"
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
