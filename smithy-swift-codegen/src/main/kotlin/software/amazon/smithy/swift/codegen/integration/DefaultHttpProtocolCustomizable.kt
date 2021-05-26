package software.amazon.smithy.swift.codegen.integration

abstract class DefaultHttpProtocolCustomizable : HttpProtocolCustomizable {
    override fun baseMiddlewares(ctx: ProtocolGenerator.GenerationContext): List<OperationMiddlewareRenderable> {
        return emptyList()
    }
}
