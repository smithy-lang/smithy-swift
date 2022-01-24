/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpHeaderMiddlewareGeneratorTests {
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
        val contents = getModelFileContents("example", "SmokeTestInput+HeaderMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct SmokeTestInputHeadersMiddleware: Runtime.Middleware {
                public let id: Swift.String = "SmokeTestInputHeadersMiddleware"
            
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
                    if let header1 = input.operationInput.header1 {
                        input.builder.withHeader(name: "X-Header1", value: Swift.String(header1))
                    }
                    if let header2 = input.operationInput.header2 {
                        input.builder.withHeader(name: "X-Header2", value: Swift.String(header2))
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
    fun `it builds headers with enums as raw values`() {
        val contents = getModelFileContents("example", "EnumInputInput+HeaderMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct EnumInputInputHeadersMiddleware: Runtime.Middleware {
                public let id: Swift.String = "EnumInputInputHeadersMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<EnumInputInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<EnumInputOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let enumHeader = input.operationInput.enumHeader {
                        input.builder.withHeader(name: "X-EnumHeader", value: Swift.String(enumHeader.rawValue))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<EnumInputInput>
                public typealias MOutput = Runtime.OperationOutput<EnumInputOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<EnumInputOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds header with idempotency token value`() {
        val contents = getModelFileContents(
            "example",
            "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput+HeaderMiddleware.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct IdempotencyTokenWithoutHttpPayloadTraitOnTokenInputHeadersMiddleware: Runtime.Middleware {
                public let id: Swift.String = "IdempotencyTokenWithoutHttpPayloadTraitOnTokenInputHeadersMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let token = input.operationInput.token {
                        input.builder.withHeader(name: "token", value: Swift.String(token))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenInput>
                public typealias MOutput = Runtime.OperationOutput<IdempotencyTokenWithoutHttpPayloadTraitOnTokenOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<IdempotencyTokenWithoutHttpPayloadTraitOnTokenOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates http headers for timestamps with format`() {
        val contents =
            getModelFileContents("example", "TimestampInputInput+HeaderMiddleware.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct TimestampInputInputHeadersMiddleware: Runtime.Middleware {
                public let id: Swift.String = "TimestampInputInputHeadersMiddleware"
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Runtime.SerializeStepInput<TimestampInputInput>,
                              next: H) -> Swift.Result<Runtime.OperationOutput<TimestampInputOutputResponse>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    if let headerEpoch = input.operationInput.headerEpoch {
                        input.builder.withHeader(name: "X-Epoch", value: Swift.String(headerEpoch.timeIntervalSince1970.clean))
                    }
                    if let headerHttpDate = input.operationInput.headerHttpDate {
                        input.builder.withHeader(name: "X-Date", value: Swift.String(headerHttpDate.rfc5322()))
                    }
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Runtime.SerializeStepInput<TimestampInputInput>
                public typealias MOutput = Runtime.OperationOutput<TimestampInputOutputResponse>
                public typealias Context = Runtime.HttpContext
                public typealias MError = Runtime.SdkError<TimestampInputOutputError>
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }
}
