package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.aws.traits.HttpChecksumTrait
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.HttpChecksumRequiredTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class ContentMD5Middleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
) : MiddlewareRenderable {
    override val name = "ContentMD5Middleware"

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        if (op.isMD5ChecksumRequired()) {
            super.render(ctx, writer, op, operationStackName)
        }
    }

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
    ) {
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        writer.write("\$N<$inputShapeName, $outputShapeName>()", ClientRuntimeTypes.Middleware.ContentMD5Middleware)
    }
}

/**
 * Check if MD5 checksum is required
 * The Md5 middleware will only be generated if the operation is marked with @httpChecksumRequired trait or if
 *   only the requestChecksumRequired property of the httpChecksum is set.
 *  https://smithy.io/2.0/aws/aws-core.html#behavior-with-httpchecksumrequired
 *
 *  ContentMD5Middleware will skip checksum calculation if flexible checksum was calculated for request already,
 *    determined by presence of a header with "x-amz-checksum-" prefix.
 */
private fun OperationShape.isMD5ChecksumRequired(): Boolean {
    val httpChecksumTrait = getTrait<HttpChecksumTrait>()
    val onlyRequestChecksumRequiredIsSetInHttpChecksumTrait =
        httpChecksumTrait?.isRequestChecksumRequired == true &&
            httpChecksumTrait.requestAlgorithmMember?.isEmpty == true &&
            httpChecksumTrait.requestValidationModeMember?.isEmpty == true &&
            httpChecksumTrait.responseAlgorithms?.isEmpty() == true
    return onlyRequestChecksumRequiredIsSetInHttpChecksumTrait || hasTrait<HttpChecksumRequiredTrait>()
}
