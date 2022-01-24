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
    fun `it builds body middleware smoke test`() {
        val contents = getModelFileContents("example", "SmokeTestInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputBodyMiddleware: Runtime.Middleware {
                public let id: Swift.String = "SmokeTestInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<SmokeTestInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<SmokeTestOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    do {
                        if try !input.operationInput.allPropertiesAreNull() {
                            let encoder = context.getEncoder()
                            let data = try encoder.encode(input.operationInput)
                            let body = Runtime.HttpBody.data(data)
                            input.builder.withBody(body)
                        }
                    } catch let err {
                        return .failure(.client(Runtime.ClientError.serializationFailed(err.localizedDescription)))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<SmokeTestInput>
                public typealias MOutput = Runtime.OperationOutput<SmokeTestOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<SmokeTestOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds body middleware for explicit string payloads`() {
        val contents = getModelFileContents("example", "ExplicitStringInput+BodyMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct ExplicitStringInputBodyMiddleware: Runtime.Middleware {
                public let id: Swift.String = "ExplicitStringInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<ExplicitStringInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<ExplicitStringOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1.data(using: .utf8)
                        let payload1body = Runtime.HttpBody.data(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<ExplicitStringInput>
                public typealias MOutput = Runtime.OperationOutput<ExplicitStringOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<ExplicitStringOutputError>
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
            public struct ExplicitBlobInputBodyMiddleware: Runtime.Middleware {
                public let id: Swift.String = "ExplicitBlobInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<ExplicitBlobInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<ExplicitBlobOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1
                        let payload1body = Runtime.HttpBody.data(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<ExplicitBlobInput>
                public typealias MOutput = Runtime.OperationOutput<ExplicitBlobOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<ExplicitBlobOutputError>
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
            public struct ExplicitBlobStreamInputBodyMiddleware: Runtime.Middleware {
                public let id: Swift.String = "ExplicitBlobStreamInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<ExplicitBlobStreamInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<ExplicitBlobStreamOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        let payload1data = payload1
                        let payload1body = Runtime.HttpBody.stream(payload1data)
                        input.builder.withBody(payload1body)
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<ExplicitBlobStreamInput>
                public typealias MOutput = Runtime.OperationOutput<ExplicitBlobStreamOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<ExplicitBlobStreamOutputError>
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
            public struct ExplicitStructInputBodyMiddleware: Runtime.Middleware {
                public let id: Swift.String = "ExplicitStructInputBodyMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<ExplicitStructInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<ExplicitStructOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let payload1 = input.operationInput.payload1 {
                        do {
                            let encoder = context.getEncoder()
                            let payload1data = try encoder.encode(payload1)
                            let payload1body = Runtime.HttpBody.data(payload1data)
                            input.builder.withBody(payload1body)
                        } catch let err {
                            return .failure(.client(ClientError.serializationFailed(err.localizedDescription)))
                        }
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<ExplicitStructInput>
                public typealias MOutput = Runtime.OperationOutput<ExplicitStructOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<ExplicitStructOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
