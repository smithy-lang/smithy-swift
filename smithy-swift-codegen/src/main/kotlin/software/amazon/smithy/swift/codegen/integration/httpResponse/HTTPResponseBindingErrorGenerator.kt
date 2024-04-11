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
import software.amazon.smithy.swift.codegen.SmithyReadWriteTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.integration.serde.json.readerSymbol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.addImports
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.utils.errorShapeName

abstract class HTTPResponseBindingErrorGenerator : HttpResponseBindingErrorGeneratable {

    abstract val serviceBaseErrorSymbol: Symbol

    override fun renderServiceError(ctx: ProtocolGenerator.GenerationContext) {
        val serviceShape = ctx.service
        val serviceName = ctx.service.id.name
        val rootNamespace = ctx.settings.moduleName
        val fileName = "./$rootNamespace/models/$serviceName+ServiceErrorHelperMethod.swift"

        ctx.delegator.useFileWriter(fileName) { writer ->
            with(writer) {
                addImport(SwiftDependency.CLIENT_RUNTIME.target)
                addImport(serviceBaseErrorSymbol.namespace)

                openBlock("extension ${ctx.symbolProvider.toSymbol(ctx.service).name}Types {", "}") {
                    openBlock(
                        "static func responseServiceErrorBinding(httpResponse: \$N, responseReader: \$N, noErrorWrapping: \$N) async throws -> \$N? {", "}",
                        ClientRuntimeTypes.Http.HttpResponse,
                        ctx.service.readerSymbol,
                        SwiftTypes.Bool,
                        SwiftTypes.Error
                    ) {
                        writer.write(
                            "let errorBodyReader = \$N.errorBodyReader(responseReader: responseReader, noErrorWrapping: noErrorWrapping)",
                            serviceBaseErrorSymbol,
                        )
                        val noErrorWrapping = ctx.service.getTrait<RestXmlTrait>()?.let { it.isNoErrorWrapping } ?: false
                        writer.write("let error = try \$N(responseReader: responseReader, noErrorWrapping: \$L)", serviceBaseErrorSymbol, noErrorWrapping)
                        openBlock("switch error.code {", "}") {
                            val serviceErrorShapes =
                                serviceShape.errors
                                    .map { ctx.model.expectShape(it) as StructureShape }
                                    .toSet()
                                    .sorted()
                            serviceErrorShapes.forEach { errorShape ->
                                val errorShapeName = errorShape.errorShapeName(ctx.symbolProvider)
                                val errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                                write(
                                    "case \$S: return try await \$L.responseErrorBinding(httpResponse: httpResponse, reader: errorBodyReader, message: error.message, requestID: error.requestID)",
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

    object RestXMLResponseBindingSectionId : SectionId

    override fun renderOperationError(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, unknownServiceErrorSymbol: Symbol) {
        val operationErrorName = "${op.toUpperCamelCase()}OutputError"
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+HttpResponseErrorBinding.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            with(writer) {
                addImport(SwiftDependency.CLIENT_RUNTIME.target)
                addImport(serviceBaseErrorSymbol.namespace)
                writer.addImports(ctx.service.responseWireProtocol)
                openBlock(
                    "enum \$L {",
                    "}",
                    operationErrorName
                ) {
                    write("")
                    openBlock(
                        "static var httpBinding: \$N<\$N, \$N> {", "}",
                        SmithyReadWriteTypes.WireResponseErrorBinding,
                        ClientRuntimeTypes.Http.HttpResponse,
                        ctx.service.readerSymbol,
                    ) {
                        val errorShapes = op.errors
                            .map { ctx.model.expectShape(it) as StructureShape }
                            .toSet()
                            .sorted()
                        val context = mapOf<String, Any>(
                            "operationErrorName" to operationErrorName,
                            "ctx" to ctx,
                            "unknownServiceErrorSymbol" to unknownServiceErrorSymbol,
                            "errorShapes" to errorShapes
                        )
                        writer.openBlock("{ httpResponse, responseDocumentClosure in", "}") {
                            declareSection(RestXMLResponseBindingSectionId, context) {
                                val noErrorWrapping = ctx.service.getTrait<RestXmlTrait>()?.let { it.isNoErrorWrapping } ?: false
                                writer.write("let responseReader = try await responseDocumentClosure(httpResponse)")
                                if (errorShapes.isNotEmpty() || ctx.service.errors.isNotEmpty()) {
                                    writer.write(
                                        "let errorBodyReader = \$N.errorBodyReader(responseReader: responseReader, noErrorWrapping: \$L)",
                                        serviceBaseErrorSymbol,
                                        noErrorWrapping
                                    )
                                }
                                if (ctx.service.errors.isNotEmpty()) {
                                    openBlock(
                                        "if let serviceError = try await \$LTypes.responseServiceErrorBinding(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: \$L) {",
                                        "}",
                                        ctx.symbolProvider.toSymbol(ctx.service).name,
                                        noErrorWrapping,
                                    ) {
                                        write("return serviceError")
                                    }
                                }
                                writer.write("let error = try \$N(responseReader: responseReader, noErrorWrapping: \$L)", serviceBaseErrorSymbol, noErrorWrapping)
                                openBlock("switch error.code {", "}") {
                                    errorShapes.forEach { errorShape ->
                                        val errorShapeName = errorShape.id.name
                                        val errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                                        write(
                                            "case \$S: return try await \$L.responseErrorBinding(httpResponse: httpResponse, reader: errorBodyReader, message: error.message, requestID: error.requestID)",
                                            errorShapeName,
                                            errorShapeType
                                        )
                                    }
                                    write("default: return try await \$unknownServiceErrorSymbol:N.makeError(httpResponse: httpResponse, message: error.message, requestID: error.requestID, typeName: error.code)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
