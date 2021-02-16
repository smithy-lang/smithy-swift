package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter

abstract class HttpProtocolClientCustomizable {
    abstract fun renderMiddlewares(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String)
    abstract fun renderContextAttributes(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape)
}
