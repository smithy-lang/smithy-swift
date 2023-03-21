/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class ServiceGeneratorTests {

    private val commonTestContents: String

    init {
        var model = javaClass.getResource("service-generator-test-operations.smithy").asSmithy()
        val writer = SwiftWriter("test")

        val settings = model.defaultSettings()
        val manifest = MockManifest()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val writers = SwiftDelegator(settings, model, manifest, provider)
        val protocolGenerationContext = ProtocolGenerator.GenerationContext(settings, model, model.serviceShapes.first(), provider, listOf(), RestJson1Trait.ID, writers)
        val generator = ServiceGenerator(
            settings,
            model,
            provider,
            writer,
            writers,
            protocolGenerationContext = protocolGenerationContext
        )
        generator.render()

        commonTestContents = writer.toString()
    }

    @Test
    fun `it renders swift protocols in separate file`() {
        val manifest = setupTest("service-generator-test-operations.smithy")
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
            "func getFooStreamingInput(input: GetFooStreamingInputInput) async throws -> GetFooStreamingInputOutputResponse",
            "func getFooNoOutput(input: GetFooNoOutputInput) async throws -> GetFooNoOutputOutputResponse",
            "func getFooStreamingOutput(input: GetFooStreamingOutputInput) async throws -> GetFooStreamingOutputOutputResponse",
            "func getFoo(input: GetFooInput) async throws -> GetFooOutputResponse",
            "func getFooNoInput(input: GetFooNoInputInput) async throws -> GetFooNoInputOutputResponse",
            "func getFooStreamingInputNoOutput(input: GetFooStreamingInputNoOutputInput) async throws -> GetFooStreamingInputNoOutputOutputResponse",
            "func getFooStreamingOutputNoInput(input: GetFooStreamingOutputNoInputInput) async throws -> GetFooStreamingOutputNoInputOutputResponse"
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

    @Test
    fun `deprecated trait on an operation`() {
        val manifest = setupTest("service-generator-test-operations.smithy")
        val exampleClientProtocol = manifest
            .getFileString("example/ExampleClientProtocol.swift").get()
        val operationWithDeprecatedTrait = """
        @available(*, deprecated)
        """.trimIndent()
        exampleClientProtocol.shouldContain(operationWithDeprecatedTrait)
    }

    @Test
    fun `it renders an operation output error`() {
        val manifest = setupTest("service-generator-test-operations.smithy")
        val renderedError = manifest.getFileString("example/models/GetFooOutputError.swift").get()
        val expected = """
        import ClientRuntime
        
        public enum GetFooOutputError: Swift.Error, Swift.Equatable {
            case getFooError(GetFooError)
            case unknown(UnknownHttpServiceError)
        }
        
        extension GetFooOutputError {
        
            /// Returns the underlying service error enclosed by this enumeration.
            ///
            /// Will return either one of this operation's predefined service errors,
            /// or a value representing an unknown error if no predefined type could
            /// be matched.
            public var serviceError: ServiceError {
                switch self {
                case .getFooError(let error): return error
                case .unknown(let error): return error
                }
            }
        }
        """.trimIndent()
        renderedError.shouldContain(expected)
    }

    private fun setupTest(modelName: String): MockManifest {
        val model = javaClass.getResource(modelName).asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "com.test#Example")
        SwiftCodegenPlugin().execute(context)
        return manifest
    }
}
