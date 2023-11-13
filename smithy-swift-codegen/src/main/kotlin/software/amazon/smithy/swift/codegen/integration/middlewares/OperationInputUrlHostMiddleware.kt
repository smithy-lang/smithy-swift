package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.EndpointTraitConstructor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.getTrait

class OperationInputUrlHostMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val operation: OperationShape,
    val requiresHost: Boolean = false
) : MiddlewareRenderable {

    override val name = "OperationInputUrlHostMiddleware"

    override val middlewareStep = MiddlewareStep.INITIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String
    ) {
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name

        var inputParameters = if (requiresHost) "host: hostOnly" else ""
        operation.getTrait<EndpointTrait>()?.let {
            val inputShape = model.expectShape(operation.input.get())
            val hostPrefix = EndpointTraitConstructor(it, inputShape).construct()
            inputParameters += if (requiresHost) ", " else ""
            inputParameters += "hostPrefix: \"$hostPrefix\""
        }
        writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$N<$inputShapeName, $outputShapeName>($inputParameters))", ClientRuntimeTypes.Middleware.URLHostMiddleware)
    }
}
