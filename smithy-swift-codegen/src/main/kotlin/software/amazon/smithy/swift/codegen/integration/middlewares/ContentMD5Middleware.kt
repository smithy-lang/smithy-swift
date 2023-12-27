package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.aws.traits.HttpChecksumTrait
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.HttpChecksumRequiredTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

class ContentMD5Middleware(
    val model: Model,
    val symbolProvider: SymbolProvider
) : MiddlewareRenderable {
    override val name = "ContentMD5Middleware"

    override val middlewareStep = MiddlewareStep.BUILDSTEP

    override val position = MiddlewarePosition.BEFORE

    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        if (op.isChecksumRequired()) {
            val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
            writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$N<$outputShapeName>())", ClientRuntimeTypes.Middleware.ContentMD5Middleware)
        }
    }
}

// TODO https://github.com/awslabs/aws-sdk-swift/issues/653
private fun OperationShape.isChecksumRequired(): Boolean =
    getTrait<HttpChecksumTrait>()?.isRequestChecksumRequired == true || hasTrait<HttpChecksumRequiredTrait>()
