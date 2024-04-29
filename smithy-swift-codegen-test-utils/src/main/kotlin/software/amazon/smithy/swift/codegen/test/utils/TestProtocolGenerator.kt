/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.test.utils

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ClientProperty
import software.amazon.smithy.swift.codegen.integration.DefaultHttpProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.DefaultRequestEncoder
import software.amazon.smithy.swift.codegen.integration.DefaultResponseDecoder
import software.amazon.smithy.swift.codegen.integration.DefaultServiceConfig
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.HttpRequestEncoder
import software.amazon.smithy.swift.codegen.integration.HttpResponseDecoder
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import software.amazon.smithy.swift.codegen.integration.codingKeys.CodingKeysCustomizationJsonName
import software.amazon.smithy.swift.codegen.integration.codingKeys.CodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.codingKeys.DefaultCodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingErrorGeneratable
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingOutputGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseGeneratable
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.integration.serde.json.StructDecodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.json.StructEncodeGenerator
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.ShapeMetadata
import software.amazon.smithy.swift.codegen.model.buildSymbol
import software.amazon.smithy.swift.codegen.utils.errorShapeName

/**
 * A test JSON-based protocol generator for the Weather service client
 */
class TestProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/json"
    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME
    override val protocol: ShapeId = ShapeId.from("common#fakeProtocol")
    override val httpProtocolClientGeneratorFactory = HttpProtocolClientGeneratorFactory()
    override val httpProtocolCustomizable = RestJsonHttpProtocolCustomizations()
    override val codingKeysGenerator: CodingKeysGenerator = DefaultCodingKeysGenerator(CodingKeysCustomizationJsonName())
    override val httpResponseGenerator: HttpResponseGeneratable = HttpResponseGenerator(
        unknownServiceErrorSymbol,
        defaultTimestampFormat,
        HttpResponseBindingOutputGenerator(),
        HttpResponseBindingErrorGenerator()
    )
    override val shouldRenderDecodableBodyStructForInputShapes = true
    override val shouldRenderCodingKeysForEncodable = true
    override val shouldRenderEncodableConformance = false

    override fun renderStructEncode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeContainingMembers: Shape,
        shapeMetadata: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format,
        path: String?
    ) {
        val encodeGenerator = StructEncodeGenerator(ctx, members, writer, defaultTimestampFormat, path)
        encodeGenerator.render()
    }
    override fun renderStructDecode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeContainingMembers: Shape,
        shapeMetadata: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format,
        path: String
    ) {
        val decodeGenerator = StructDecodeGenerator(ctx, members, writer, defaultTimestampFormat, path)
        decodeGenerator.render()
    }

    override fun addProtocolSpecificMiddleware(ctx: ProtocolGenerator.GenerationContext, operation: OperationShape) {
        // Intentionally empty
    }

    override fun generateMessageMarshallable(ctx: ProtocolGenerator.GenerationContext) {
    }

    override fun generateMessageUnmarshallable(ctx: ProtocolGenerator.GenerationContext) {
    }

    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext): Int {
        val requestTestBuilder = HttpProtocolUnitTestRequestGenerator.Builder()
        val responseTestBuilder = HttpProtocolUnitTestResponseGenerator.Builder()
        val errorTestBuilder = HttpProtocolUnitTestErrorGenerator.Builder()

        return HttpProtocolTestGenerator(
            ctx,
            requestTestBuilder,
            responseTestBuilder,
            errorTestBuilder,
            httpProtocolCustomizable,
            operationMiddleware,
            getProtocolHttpBindingResolver(ctx, defaultContentType),
        ).generateProtocolTests()
    }
}

class HttpRequestJsonEncoder(
    requestEncoderOptions: MutableMap<String, String> = mutableMapOf()
) : HttpRequestEncoder(ClientRuntimeTypes.Serde.JSONEncoder, requestEncoderOptions)

class HttpRequestJsonDecoder(
    requestDecoderOptions: MutableMap<String, String> = mutableMapOf()
) : HttpResponseDecoder(ClientRuntimeTypes.Serde.JSONDecoder, requestDecoderOptions)

class RestJsonHttpProtocolCustomizations() : DefaultHttpProtocolCustomizations() {
    override fun getClientProperties(): List<ClientProperty> {
        val properties = mutableListOf<ClientProperty>()
        val requestEncoderOptions = mutableMapOf<String, String>()
        val responseDecoderOptions = mutableMapOf<String, String>()
        requestEncoderOptions["dateEncodingStrategy"] = ".secondsSince1970"
        requestEncoderOptions["nonConformingFloatEncodingStrategy"] = ".convertToString(positiveInfinity: \"Infinity\", negativeInfinity: \"-Infinity\", nan: \"NaN\")"
        responseDecoderOptions["dateDecodingStrategy"] = ".secondsSince1970"
        responseDecoderOptions["nonConformingFloatDecodingStrategy"] = ".convertFromString(positiveInfinity: \"Infinity\", negativeInfinity: \"-Infinity\", nan: \"NaN\")"
        properties.add(HttpRequestJsonEncoder(requestEncoderOptions))
        properties.add(HttpRequestJsonDecoder(responseDecoderOptions))
        return properties
    }
}

class HttpResponseBindingErrorGenerator : HttpResponseBindingErrorGeneratable {
    override fun renderServiceError(ctx: ProtocolGenerator.GenerationContext) {
        val serviceShape = ctx.service
        val serviceName = ctx.service.id.name
        val rootNamespace = ctx.settings.moduleName
        val fileName = "./$rootNamespace/models/$serviceName+ServiceErrorHelperMethod.swift"

        ctx.delegator.useFileWriter(fileName) { writer ->
            with(writer) {
                addImport(SwiftDependency.CLIENT_RUNTIME.target)
                addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
                openBlock(
                    "func makeServiceError(_ httpResponse: \$N, _ decoder: \$D, _ error: \$N, _ id: String?) async throws -> \$N? {",
                    "}",
                    ClientRuntimeTypes.Http.HttpResponse,
                    ClientRuntimeTypes.Serde.ResponseDecoder,
                    JSON_ERROR_SYMBOL,
                    SwiftTypes.Error
                ) {
                    openBlock("switch error.errorType {", "}") {
                        val serviceErrorShapes =
                            serviceShape.errors
                                .map { ctx.model.expectShape(it) as StructureShape }
                                .toSet()
                                .sorted()
                        serviceErrorShapes.forEach { errorShape ->
                            val errorShapeName = errorShape.errorShapeName(ctx.symbolProvider)
                            val errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                            write(
                                "case \$S: return try await \$L(httpResponse: httpResponse, decoder: decoder, message: error.errorMessage, requestID: id)",
                                errorShapeName,
                                errorShapeType
                            )
                        }
                        write("default: return nil")
                    }
                }
            }
        }
    }

    override fun renderOperationError(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape,
        unknownServiceErrorSymbol: Symbol
    ) {
        val operationErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+HttpResponseBinding.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
            with(writer) {

                openBlock(
                    "enum \$L: \$N {",
                    "}",
                    operationErrorName,
                    ClientRuntimeTypes.Http.HttpResponseErrorBinding
                ) {
                    openBlock(
                        "static func makeError(httpResponse: \$N, decoder: \$D) async throws -> \$N {", "}",
                        ClientRuntimeTypes.Http.HttpResponse,
                        ClientRuntimeTypes.Serde.ResponseDecoder,
                        SwiftTypes.Error
                    ) {
                        write("let defaultError = try await \$N(httpResponse: httpResponse)", JSON_ERROR_SYMBOL)

                        if (ctx.service.errors.isNotEmpty()) {
                            write("let serviceError = try await makeServiceError(httpResponse, decoder, restJSONError, requestID)")
                            write("if let error = serviceError { return error }")
                        }

                        openBlock("switch defaultError.errorType {", "}") {
                            val errorShapes = op.errors
                                .map { ctx.model.expectShape(it) as StructureShape }
                                .toSet()
                                .sorted()
                            errorShapes.forEach { errorShape ->
                                var errorShapeName = errorShape.errorShapeName(ctx.symbolProvider)
                                var errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                                write(
                                    "case \$S: return try await \$L(httpResponse: httpResponse, decoder: decoder, message: defaultError.errorMessage)",
                                    errorShapeName,
                                    errorShapeType
                                )
                            }
                            write(
                                "default: return try await \$N.makeError(httpResponse: httpResponse, message: defaultError.errorMessage, typeName: defaultError.errorType)",
                                unknownServiceErrorSymbol
                            )
                        }
                    }
                }
            }
        }
    }
}

class HttpProtocolClientGeneratorFactory :
    software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGeneratorFactory {
    override fun createHttpProtocolClientGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        httpBindingResolver: HttpBindingResolver,
        writer: SwiftWriter,
        serviceName: String,
        defaultContentType: String,
        httpProtocolCustomizable: HttpProtocolCustomizable,
        operationMiddleware: OperationMiddleware,
    ): HttpProtocolClientGenerator {
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val config = getConfigClass(writer, serviceSymbol.name)
        return HttpProtocolClientGenerator(ctx, writer, config, httpBindingResolver, defaultContentType, httpProtocolCustomizable, operationMiddleware)
    }

    private fun getClientProperties(ctx: ProtocolGenerator.GenerationContext): List<ClientProperty> {
        return mutableListOf(
            DefaultRequestEncoder(),
            DefaultResponseDecoder(),
        )
    }

    private fun getConfigClass(writer: SwiftWriter, serviceName: String): ServiceConfig {
        return DefaultServiceConfig(writer, serviceName)
    }
}

private val JSON_ERROR_SYMBOL: Symbol = buildSymbol {
    this.name = "JSONError"
    this.namespace = SwiftDependency.SMITHY_TEST_UTIL.target
    dependency(SwiftDependency.SMITHY_TEST_UTIL)
}
