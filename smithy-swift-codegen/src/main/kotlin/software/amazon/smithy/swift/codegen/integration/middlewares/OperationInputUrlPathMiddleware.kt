package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class OperationInputUrlPathMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    private val inputParameters: String
) : MiddlewareRenderable {

    override val name = "OperationInputUrlPathMiddleware"

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        val params = "".takeIf { inputParameters.isEmpty() } ?: "$inputParameters, "
        writer.write(
            "\$N<\$L, \$L>(\$L\$L.urlPathProvider(_:))",
            ClientRuntimeTypes.Middleware.URLPathMiddleware,
            inputShapeName,
            outputShapeName,
            params,
            inputShapeName
        )
    }
}
