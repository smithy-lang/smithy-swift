package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter

abstract class HttpProtocolClientCustomizable {
    abstract fun renderMiddlewares(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String)
    abstract fun renderSerializeMiddleware(
        writer: SwiftWriter,
        test: HttpRequestTestCase,
        operationStack: String,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorName: String,
        hasHttpBody: Boolean
    )
    abstract fun renderContextAttributes(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape)
    abstract fun addImport(writer: SwiftWriter)
}
