package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

class OperationInputBodyMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val alwaysSendBody: Boolean = false
) : MiddlewareRenderable {

    override val name = "OperationInputBodyMiddleware"

    override val middlewareStep = MiddlewareStep.SERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        val inputShape = MiddlewareShapeUtils.inputShape(model, op)
        val inputSymbol = symbolProvider.toSymbol(inputShape)
        val outputSymbol = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
        val xmlName = inputShape.getTrait<XmlNameTrait>()?.value
        val isRestXML = ctx.service.hasTrait<RestXmlTrait>()

        if (alwaysSendBody) {
            if (isRestXML && xmlName != null) {
                addXMLMiddleware(writer, operationStackName, xmlName, inputSymbol, outputSymbol)
            } else {
                addEncodableMiddleware(writer, operationStackName, xmlName, inputSymbol, outputSymbol)
            }
        } else if (MiddlewareShapeUtils.hasHttpBody(model, op)) {
            if (MiddlewareShapeUtils.bodyIsHttpPayload(model, op)) {
                writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$NBodyMiddleware())", inputSymbol)
            } else {
                if (isRestXML && xmlName != null) {
                    addXMLMiddleware(writer, operationStackName, xmlName, inputSymbol, outputSymbol)
                } else {
                    addEncodableMiddleware(writer, operationStackName, xmlName, inputSymbol, outputSymbol)
                }
            }
        }
    }

    private fun addXMLMiddleware(writer: SwiftWriter, operationStackName: String, xmlName: String, inputSymbol: Symbol, outputSymbol: Symbol) {
        writer.addImport(SwiftDependency.SMITHY_XML.target)
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N>(serializer: { try SmithyXML.DocumentWriter().write($$0, rootElement: \$S, valueWriter: \$N.write(_:to:)) }))",
            operationStackName, middlewareStep.stringValue(), position.stringValue(), ClientRuntimeTypes.Middleware.SerializableBodyMiddleware, inputSymbol, outputSymbol, xmlName, inputSymbol
        )
    }

    private fun addEncodableMiddleware(writer: SwiftWriter, operationStackName: String, xmlName: String?, inputSymbol: Symbol, outputSymbol: Symbol) {
        val rootElement = xmlName?.let { "\"${it}\"" } ?: "nil"
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N>(serializer: { try encoder.encode($$0) }))",
            operationStackName, middlewareStep.stringValue(), position.stringValue(), ClientRuntimeTypes.Middleware.SerializableBodyMiddleware, inputSymbol, outputSymbol
        )
    }
}
