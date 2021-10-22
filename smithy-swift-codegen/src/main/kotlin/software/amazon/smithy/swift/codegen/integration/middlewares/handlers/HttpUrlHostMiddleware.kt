package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.EndpointTraitConstructor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.steps.OperationInitializeStep

class HttpUrlHostMiddleware(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val op: OperationShape,
    inputSymbol: Symbol,
    outputSymbol: Symbol,
    outputErrorSymbol: Symbol,
    private val writer: SwiftWriter
) : Middleware(writer, inputSymbol, OperationInitializeStep(inputSymbol, outputSymbol, outputErrorSymbol)) {
    companion object {
        fun renderMiddleware(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, httpBindingResolver: HttpBindingResolver) {
            val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
            val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
            val outputErrorSymbol = MiddlewareShapeUtils.outputErrorSymbol(op)
            val rootNamespace = MiddlewareShapeUtils.rootNamespace(ctx.settings)

            val headerMiddlewareSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${inputSymbol.name}+UrlPathMiddleware.swift")
                .name(inputSymbol.name)
                .build()
            ctx.delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                val queryItemMiddleware = HttpUrlHostMiddleware(ctx, op, inputSymbol, outputSymbol, outputErrorSymbol, writer)
                MiddlewareGenerator(writer, queryItemMiddleware).generate()
            }
        }
    }
    override val typeName = "${inputSymbol.name}URLHostMiddleware"

    override fun generateMiddlewareClosure() {
        writer.write("var copiedContext = context")
        writer.openBlock("if let host = host {", "}") {
            writer.write("copiedContext.attributes.set(key: AttributeKey<String>(name: \"Host\"), value: host)")
        }

        op.getTrait(EndpointTrait::class.java).ifPresent {
            val inputShape = ctx.model.expectShape(op.input.get())
            val hostPrefix = EndpointTraitConstructor(it, inputShape).construct()
            writer.write("copiedContext.attributes.set(key: AttributeKey<String>(name: \"HostPrefix\"), value: \"\$L\")", hostPrefix)
        }
    }

    override fun generateInit() {
        writer.write("let host: \$T", SwiftTypes.String)
        writer.write("")
        writer.openBlock("public init(host: \$D) {", "}", SwiftTypes.String) {
            writer.write("self.host = host")
        }
    }
    override fun renderReturn() {
        writer.write("return next.handle(context: copiedContext, input: input)")
    }
}
