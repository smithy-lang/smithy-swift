/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.aws.traits.protocols.AwsQueryErrorTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.model.getTrait

class HttpResponseBindingErrorNarrowGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val op: OperationShape,
    val unknownServiceErrorSymbol: Symbol
) {
    object HttpResponseBindingErrorNarrowGeneratorSectionId : SectionId

    fun render() {
        val errorShapes = op.errors.map { ctx.model.expectShape(it) as StructureShape }.toSet().sorted()
        val operationErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+HttpResponseBinding.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(unknownServiceErrorSymbol)
            val unknownServiceErrorType = unknownServiceErrorSymbol.name

            val context = mapOf(
                "ctx" to ctx,
                "unknownServiceErrorType" to unknownServiceErrorType,
                "operationErrorName" to operationErrorName,
                "errorShapes" to errorShapes
            )
            writer.declareSection(HttpResponseBindingErrorNarrowGeneratorSectionId, context) {
                writer.openBlock("extension \$L {", "}", operationErrorName) {
                    writer.openBlock(
                        "public init(errorType: \$T, httpResponse: \$N, decoder: \$D, message: \$D, requestID: \$D) throws {", "}",
                        SwiftTypes.String, ClientRuntimeTypes.Http.HttpResponse, ClientRuntimeTypes.Serde.ResponseDecoder, SwiftTypes.String, SwiftTypes.String
                    ) {
                        writer.write("switch errorType {")
                        for (errorShape in errorShapes) {
                            var errorShapeName = resolveErrorShapeName(errorShape)
                            var errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                            var errorShapeEnumCase = errorShapeType.decapitalize()
                            writer.write("case \$S : self = .\$L(try \$L(httpResponse: httpResponse, decoder: decoder, message: message, requestID: requestID))", errorShapeName, errorShapeEnumCase, errorShapeType)
                        }
                        writer.write("default : self = .unknown($unknownServiceErrorType(httpResponse: httpResponse, message: message, requestID: requestID, errorType: errorType))")
                        writer.write("}")
                    }
                }
            }
        }
    }

    // TODO: Move to be called from a protocol
    private fun resolveErrorShapeName(errorShape: StructureShape): String {
        errorShape.getTrait<AwsQueryErrorTrait>()?.let {
            return it.code
        } ?: run {
            return ctx.symbolProvider.toSymbol(errorShape).name
        }
    }
}
