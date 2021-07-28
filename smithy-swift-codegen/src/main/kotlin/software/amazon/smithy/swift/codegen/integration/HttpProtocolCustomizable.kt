package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter

interface HttpProtocolCustomizable {
    fun renderMiddlewares(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String)

    fun renderInternals(ctx: ProtocolGenerator.GenerationContext) {
        // Default implementation is no-op
    }

    fun renderMiddlewareForGeneratedRequestTests(
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

    fun renderContextAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceShape: ServiceShape,
        op: OperationShape
    ) {
        // Default implementation is no-op
    }

    fun getClientProperties(): List<ClientProperty> {
        return emptyList()
    }

    fun getServiceClient(ctx: ProtocolGenerator.GenerationContext,
                         writer: SwiftWriter,
                         serviceConfig: ServiceConfig): HttpProtocolServiceClient

    fun customRenderBodyComparison(test: HttpRequestTestCase): ((SwiftWriter, HttpRequestTestCase, Symbol, Shape, String, String) -> Unit)? {
        return null
    }

    fun alwaysHasHttpBody(): Boolean {
        return false
    }

    /**
     * Get all of the middleware that should be installed into the operation's middleware stack (`SdkOperationExecution`)
     * This is the function that protocol client generators should invoke to get the fully resolved set of middleware
     * to be rendered (i.e. after integrations have had a chance to intercept). The default set of middleware for
     * a protocol can be overridden by [baseMiddlewares].
     */
    fun operationMiddlewares(ctx: ProtocolGenerator.GenerationContext, op: OperationShape): List<OperationMiddlewareRenderable>

    fun baseMiddlewares(ctx: ProtocolGenerator.GenerationContext, op: OperationShape): List<OperationMiddlewareRenderable>
}
