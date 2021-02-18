package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter

abstract class HttpProtocolClientCustomizable {
    open fun renderMiddlewares(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        // Default implementation is no-op
    }
    open fun renderSerializeMiddleware(
        writer: SwiftWriter,
        test: HttpRequestTestCase,
        operationStack: String,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorName: String,
        hasHttpBody: Boolean
    ) {
        // Default implementation is no-op
    }
    abstract fun renderContextAttributes(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape)
}
