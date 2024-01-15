package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class ResponseClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
    val op: OperationShape
) {

    fun render(): String {
        return when {
            ctx.service.responseWireProtocol == WireProtocol.XML -> {
                val outputShape = ctx.model.expectShape(op.outputShape)
                val outputSymbol = ctx.symbolProvider.toSymbol(outputShape)
                writer.format(
                    "responseClosure(\$N.httpBinding, responseDocumentBinding())",
                    outputSymbol
                )
            }
            else -> "responseClosure(decoder: decoder)"
        }
    }
}
