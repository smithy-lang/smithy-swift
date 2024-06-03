package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.aws.traits.HttpChecksumTrait
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.HttpChecksumRequiredTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class ContentMD5Middleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
) : MiddlewareRenderable {
    override val name = "ContentMD5Middleware"

    override val middlewareStep = MiddlewareStep.BUILDSTEP

    override val position = MiddlewarePosition.BEFORE

    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        if (op.isMD5ChecksumRequired()) {
            super.render(ctx, writer, op, operationStackName)
        }
    }

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        writer.write("\$N<$inputShapeName, $outputShapeName>()", ClientRuntimeTypes.Middleware.ContentMD5Middleware)
    }
}

/**
 * Check if MD5 checksum is required
 * The Md5 middleware will only be installed if the operation requires a checksum and the user has not opted-in to flexible checksums.
 */
private fun OperationShape.isMD5ChecksumRequired(): Boolean =
    // the checksum requirement can be modeled in either HttpChecksumTrait's `requestChecksumRequired` or the HttpChecksumRequired trait
    getTrait<HttpChecksumTrait>()?.isRequestChecksumRequired == true || hasTrait<HttpChecksumRequiredTrait>()
