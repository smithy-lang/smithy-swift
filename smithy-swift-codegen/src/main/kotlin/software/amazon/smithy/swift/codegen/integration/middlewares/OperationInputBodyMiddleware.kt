package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.aws.traits.protocols.AwsJson1_1Trait
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.DocumentShape
import software.amazon.smithy.model.shapes.EnumShape
import software.amazon.smithy.model.shapes.IntEnumShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.HttpPayloadTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.DocumentWritingClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WritingClosureUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.hasTrait

class OperationInputBodyMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val alwaysSendBody: Boolean = false
) : MiddlewareRenderable {

    override val name = "OperationInputBodyMiddleware"

    override val middlewareStep = MiddlewareStep.SERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        if (!alwaysSendBody && !MiddlewareShapeUtils.hasHttpBody(ctx.model, op)) return
        val writingClosureUtils = WritingClosureUtils(ctx, writer)
        val documentWritingClosureUtils = DocumentWritingClosureUtils(ctx, writer)
        val inputShape = MiddlewareShapeUtils.inputShape(model, op)
        val inputSymbol = symbolProvider.toSymbol(inputShape)
        val outputSymbol = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
        val writerSymbol = documentWritingClosureUtils.writerSymbol()
        var payloadShape = inputShape
        var keyPath = "\\.self"
        var payloadWritingClosure = writingClosureUtils.writingClosure(payloadShape)
        var documentWritingClosure = documentWritingClosureUtils.closure(payloadShape)
        var isPayloadMember = false
        var defaultBody = "\"{}\"".takeIf { ctx.service.hasTrait<AwsJson1_0Trait>() || ctx.service.hasTrait<AwsJson1_1Trait>() || ctx.service.hasTrait<RestJson1Trait>() } ?: "nil"
        var payloadMember = inputShape.members().find { it.hasTrait<HttpPayloadTrait>() }
        payloadMember?.let { payloadMember ->
            payloadShape = ctx.model.expectShape(payloadMember.target)
            val memberName = ctx.symbolProvider.toMemberName(payloadMember)
            keyPath = writer.format("\\.\$L", memberName)
            payloadWritingClosure = writingClosureUtils.writingClosure(payloadMember)
            documentWritingClosure = documentWritingClosureUtils.closure(payloadMember)
            isPayloadMember = true
        }
        val isStreaming = payloadShape.hasTrait<StreamingTrait>()
        val payloadSymbol = ctx.symbolProvider.toSymbol(payloadShape)

        when (payloadShape) {
            is UnionShape -> {
                if (isStreaming) {
                    addEventStreamMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, keyPath, defaultBody)
                } else {
                    addAggregateMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, writerSymbol, documentWritingClosure, payloadWritingClosure, keyPath, defaultBody, isPayloadMember)
                }
            }
            is StructureShape, is DocumentShape -> {
                addAggregateMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, writerSymbol, documentWritingClosure, payloadWritingClosure, keyPath, defaultBody, isPayloadMember)
            }
            is BlobShape -> {
                addBlobStreamMiddleware(writer, operationStackName, inputSymbol, outputSymbol, keyPath, defaultBody, isStreaming)
            }
            is EnumShape -> {
                addEnumMiddleware(writer, operationStackName, ClientRuntimeTypes.Middleware.EnumBodyMiddleware, inputSymbol, outputSymbol, payloadSymbol, keyPath)
            }
            is IntEnumShape -> {
                addEnumMiddleware(writer, operationStackName, ClientRuntimeTypes.Middleware.IntEnumBodyMiddleware, inputSymbol, outputSymbol, payloadSymbol, keyPath)
            }
            is StringShape -> {
                addStringMiddleware(writer, operationStackName, inputSymbol, outputSymbol, keyPath)
            }
        }
    }

    private fun addAggregateMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, payloadSymbol: Symbol, writerSymbol: Symbol, documentWritingClosure: String, payloadWritingClosure: String, keyPath: String, defaultBody: String, isPayloadMember: Boolean) {
        if (isPayloadMember) {
            addPayloadBodyMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, writerSymbol, documentWritingClosure, payloadWritingClosure, keyPath, defaultBody)
        } else {
            addBodyMiddleware(writer, operationStackName, inputSymbol, outputSymbol, writerSymbol, documentWritingClosure, payloadWritingClosure)
        }
    }

    private fun addBodyMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, writerSymbol: Symbol, documentWritingClosure: String, payloadWritingClosure: String) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N>(documentWritingClosure: \$L, inputWritingClosure: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.BodyMiddleware,
            inputSymbol,
            outputSymbol,
            writerSymbol,
            documentWritingClosure,
            payloadWritingClosure,
        )
    }

    private fun addPayloadBodyMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, payloadSymbol: Symbol, writerSymbol: Symbol, documentWritingClosure: String, payloadWritingClosure: String, keyPath: String, defaultBody: String) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N, \$N>(documentWritingClosure: \$L, inputWritingClosure: \$L, keyPath: \$L, defaultBody: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.PayloadBodyMiddleware,
            inputSymbol,
            outputSymbol,
            payloadSymbol,
            writerSymbol,
            documentWritingClosure,
            payloadWritingClosure,
            keyPath,
            defaultBody
        )
    }

    private fun addEventStreamMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, payloadSymbol: Symbol, keyPath: String, defaultBody: String) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N>(keyPath: \$L, defaultBody: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.EventStreamBodyMiddleware,
            inputSymbol,
            outputSymbol,
            payloadSymbol,
            keyPath,
            defaultBody
        )
    }

    private fun addBlobStreamMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, keyPath: String, defaultBody: String, streaming: Boolean) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N>(keyPath: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.BlobStreamBodyMiddleware.takeIf { streaming } ?: ClientRuntimeTypes.Middleware.BlobBodyMiddleware,
            inputSymbol,
            outputSymbol,
            keyPath
        )
    }

    private fun addEnumMiddleware(writer: SwiftWriter, operationStackName: String, middlewareSymbol: Symbol, inputSymbol: Symbol, outputSymbol: Symbol, payloadSymbol: Symbol, keyPath: String) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N>(keyPath: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            middlewareSymbol,
            inputSymbol,
            outputSymbol,
            payloadSymbol,
            keyPath
        )
    }

    private fun addStringMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, keyPath: String) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N>(keyPath: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.StringBodyMiddleware,
            inputSymbol,
            outputSymbol,
            keyPath
        )
    }
}
