/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpBodyMiddlewareTests {
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
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }

    @Test
    fun `it builds body middleware for explicit string payloads`() {
        val contents = getModelFileContents("example", "ExplicitStringInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitStringInputBodyMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "ExplicitStringInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: ClientRuntime.SerializeStepInput<ExplicitStringInput>,
                              next: H) async throws -> ClientRuntime.OperationOutput<ExplicitStringOutputResponse>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1.data(using: .utf8)
                        let payload1body = ClientRuntime.HttpBody.data(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return try await next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<ExplicitStringInput>
                public typealias MOutput = ClientRuntime.OperationOutput<ExplicitStringOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitBlobInputBodyMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "ExplicitBlobInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: ClientRuntime.SerializeStepInput<ExplicitBlobInput>,
                              next: H) async throws -> ClientRuntime.OperationOutput<ExplicitBlobOutputResponse>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1
                        let payload1body = ClientRuntime.HttpBody.data(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return try await next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<ExplicitBlobInput>
                public typealias MOutput = ClientRuntime.OperationOutput<ExplicitBlobOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit streaming blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobStreamInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitBlobStreamInputBodyMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "ExplicitBlobStreamInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: ClientRuntime.SerializeStepInput<ExplicitBlobStreamInput>,
                              next: H) async throws -> ClientRuntime.OperationOutput<ExplicitBlobStreamOutputResponse>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1
                        let payload1body = ClientRuntime.HttpBody.stream(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return try await next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<ExplicitBlobStreamInput>
                public typealias MOutput = ClientRuntime.OperationOutput<ExplicitBlobStreamOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit struct payloads`() {
        val contents = getModelFileContents("example", "ExplicitStructInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitStructInputBodyMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "ExplicitStructInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: ClientRuntime.SerializeStepInput<ExplicitStructInput>,
                              next: H) async throws -> ClientRuntime.OperationOutput<ExplicitStructOutputResponse>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    if let payload1 = input.operationInput.payload1 {
                        do {
                            let encoder = context.getEncoder()
                            let payload1data = try encoder.encode(payload1)
                            let payload1body = ClientRuntime.HttpBody.data(payload1data)
                            input.builder.withBody(payload1body)
                        } catch let err {
                            throw SdkError<ExplicitStructOutputError>.client(ClientRuntime.ClientError.serializationFailed(err.localizedDescription))
                        }
                    }
                    return try await next.handle(context: context, input: input)
                }
            
                public typealias MInput = ClientRuntime.SerializeStepInput<ExplicitStructInput>
                public typealias MOutput = ClientRuntime.OperationOutput<ExplicitStructOutputResponse>
                public typealias Context = ClientRuntime.HttpContext
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
