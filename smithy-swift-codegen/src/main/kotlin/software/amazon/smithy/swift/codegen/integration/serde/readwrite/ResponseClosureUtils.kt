package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class ResponseClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
    val op: OperationShape
) {

    fun render(): String {
        writer.addImport(SwiftDependency.SMITHY_READ_WRITE.target)
        val outputShape = ctx.model.expectShape(op.outputShape)
        val outputSymbol = ctx.symbolProvider.toSymbol(outputShape)
        return writer.format("\$N.httpOutput(from:)", outputSymbol)
    }
}
