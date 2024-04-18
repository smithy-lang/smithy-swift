/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.addImports
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.struct.readerSymbol
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.utils.errorShapeName

class HTTPResponseBindingErrorGenerator(
    val customizations: HTTPProtocolCustomizable,
) {

    fun renderServiceError(ctx: ProtocolGenerator.GenerationContext) {
        val serviceShape = ctx.service
        val serviceName = ctx.service.id.name
        val rootNamespace = ctx.settings.moduleName
        val fileName = "./$rootNamespace/models/$serviceName+ServiceErrorHelperMethod.swift"

        ctx.delegator.useFileWriter(fileName) { writer ->
            with(writer) {
                addImport(SwiftDependency.CLIENT_RUNTIME.target)
                addImport(customizations.baseErrorSymbol.namespace)
                openBlock(
                    "extension \$LTypes {",
                    "}",
                    ctx.symbolProvider.toSymbol(ctx.service).name
                ) {
                    openBlock(
                        "static func responseServiceErrorBinding(baseError: \$N) throws -> \$N? {", "}",
                        customizations.baseErrorSymbol,
                        SwiftTypes.Error
                    ) {
                        openBlock("switch baseError.code {", "}") {
                            val serviceErrorShapes =
                                serviceShape.errors
                                    .map { ctx.model.expectShape(it) as StructureShape }
                                    .toSet()
                                    .sorted()
                            serviceErrorShapes.forEach { errorShape ->
                                val errorShapeName = errorShape.errorShapeName(ctx.symbolProvider)
                                val errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                                write(
                                    "case \$S: return try \$L.makeError(baseError: baseError)",
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
    }

    fun renderOperationError(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, unknownServiceErrorSymbol: Symbol) {
        val operationErrorName = "${op.toUpperCamelCase()}OutputError"
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+HttpResponseErrorBinding.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(customizations.baseErrorSymbol.namespace)
            writer.addImports(ctx.service.responseWireProtocol)
            writer.openBlock("enum \$L {", "}", operationErrorName) {
                writer.write("")
                writer.openBlock(
                    "static func httpError(from httpResponse: \$N) async throws -> \$N {", "}",
                    ClientRuntimeTypes.Http.HttpResponse,
                    SwiftTypes.Error,
                ) {
                    val errorShapes = op.errors
                        .map { ctx.model.expectShape(it) as StructureShape }
                        .toSet()
                        .sorted()
                    writer.write("let data = try await httpResponse.data()")
                    writer.write("let responseReader = try \$N.from(data: data)", ctx.service.readerSymbol)
                    val noErrorWrapping = ctx.service.getTrait<RestXmlTrait>()?.isNoErrorWrapping ?: false
                    writer.write(
                        "let baseError = try \$N(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: \$L)",
                        customizations.baseErrorSymbol,
                        noErrorWrapping
                    )
                    writer.write("if let error = baseError.customError() { return error }")
                    if (ctx.service.errors.isNotEmpty()) {
                        writer.openBlock(
                            "if let serviceError = try \$LTypes.responseServiceErrorBinding(baseError: baseError) {",
                            "}",
                            ctx.symbolProvider.toSymbol(ctx.service).name,
                        ) {
                            writer.write("return serviceError")
                        }
                    }
                    writer.openBlock("switch baseError.code {", "}") {
                        errorShapes.forEach { errorShape ->
                            val errorShapeName = errorShape.errorShapeName(ctx.symbolProvider)
                            val errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                            writer.write(
                                "case \$S: return try \$L.makeError(baseError: baseError)",
                                errorShapeName,
                                errorShapeType
                            )
                        }
                        writer.write(
                            "default: return try \$N.makeError(baseError: baseError)",
                            unknownServiceErrorSymbol
                        )
                    }
                }
            }
        }
    }
}
