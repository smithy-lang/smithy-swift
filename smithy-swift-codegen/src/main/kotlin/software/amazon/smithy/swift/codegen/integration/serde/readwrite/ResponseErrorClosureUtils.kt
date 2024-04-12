package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils

class ResponseErrorClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
    val op: OperationShape
) {

    fun render(): String {
        val outputErrorSymbol = MiddlewareShapeUtils.outputErrorSymbol(op)
        return writer.format(
            "wireResponseErrorClosure(\$N.httpErrorBinding, wireResponseDocumentBinding())",
            outputErrorSymbol
        )
    }
}
