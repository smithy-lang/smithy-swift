/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.aws.traits.protocols.AwsQueryErrorTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.model.getTrait

class CodedErrorGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val op: OperationShape,
    val unknownServiceErrorSymbol: Symbol
) {
    object CodedErrorGeneratorSectionId : SectionId

    fun render() {
        val errorShapes = op.errors.map { ctx.model.expectShape(it) as StructureShape }.toSet().sorted()
        val operationErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+CodedError.swift")
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
            writer.declareSection(CodedErrorGeneratorSectionId, context) {
                writer.openBlock("extension \$L: CodedError {", "}", operationErrorName) {
                    writer.write("")
                    writer.write("/// The error code for this error, or `nil` if the code could not be determined.")
                    writer.write("/// How this code is determined depends on the protocol used to decode the error response.")
                    writer.openBlock("public var errorCode: String? {", "}") {
                        writer.write("switch self {")
                        for (errorShape in errorShapes) {
                            var errorShapeName = resolveErrorShapeName(errorShape)
                            var errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                            var errorShapeEnumCase = errorShapeType.decapitalize()
                            writer.write("case .\$L: return \$S", errorShapeEnumCase, errorShapeName)
                        }
                        writer.write("case .unknown(let error): return error.errorCode")
                        writer.write("}")
                    }
                }
            }
        }
    }

    private fun resolveErrorShapeName(errorShape: StructureShape): String {
        errorShape.getTrait<AwsQueryErrorTrait>()?.let {
            return it.code
        } ?: run {
            return ctx.symbolProvider.toSymbol(errorShape).name
        }
    }
}
