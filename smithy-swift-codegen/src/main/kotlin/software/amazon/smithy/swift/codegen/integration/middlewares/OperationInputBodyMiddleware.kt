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
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.NodeInfoUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WritingClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.addImports
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.struct.writerSymbol
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.targetOrSelf
import software.amazon.smithy.swift.codegen.supportsStreamingAndIsRPC

class OperationInputBodyMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    private val alwaysSendBody: Boolean = false
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
        val nodeInfoUtils = NodeInfoUtils(ctx, writer, ctx.service.requestWireProtocol)
        val inputShape = MiddlewareShapeUtils.inputShape(model, op)
        val inputSymbol = symbolProvider.toSymbol(inputShape)
        val outputSymbol = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
        val writerSymbol = ctx.service.writerSymbol
        var payloadShape = inputShape
        var keyPath = "\\.self"
        var payloadWritingClosure = writingClosureUtils.writingClosure(payloadShape)
        var rootNodeInfo = nodeInfoUtils.nodeInfo(payloadShape, true)
        var isPayloadMember = false
        val defaultBody = "\"{}\"".takeIf { ctx.service.hasTrait<AwsJson1_0Trait>() || ctx.service.hasTrait<AwsJson1_1Trait>() || ctx.service.hasTrait<RestJson1Trait>() } ?: "nil"
        var payloadMember = inputShape.members().find { it.hasTrait<HttpPayloadTrait>() }
        var sendInitialRequest = false
        // RPC-based protocols do not support HTTP traits.
        // AWSQuery & EC2Query are ignored because they don't support streaming at all.
        if (supportsStreamingAndIsRPC(ctx.protocol)) {
            sendInitialRequest = true
            // Get "implicit payload" for input shape in RPC based protocols
            // ...given only one member can have @streaming trait.
            payloadMember = inputShape.members().find { it.targetOrSelf(ctx.model).hasTrait<StreamingTrait>() }
        }
        payloadMember?.let {
            payloadShape = ctx.model.expectShape(it.target)
            val memberName = ctx.symbolProvider.toMemberName(it)
            keyPath = writer.format("\\.\$L", memberName)
            payloadWritingClosure = writingClosureUtils.writingClosure(it)
            rootNodeInfo = nodeInfoUtils.nodeInfo(it, true)
            isPayloadMember = true
        }
        val isStreaming = payloadShape.hasTrait<StreamingTrait>()
        val payloadSymbol = ctx.symbolProvider.toSymbol(payloadShape)
        val requestWireProtocol = ctx.service.requestWireProtocol

        when (payloadShape) {
            is UnionShape -> {
                if (isStreaming) {
                    addEventStreamMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, keyPath, defaultBody, requestWireProtocol, sendInitialRequest)
                } else {
                    writer.addImports(ctx.service.requestWireProtocol)
                    addAggregateMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, writerSymbol, rootNodeInfo, payloadWritingClosure, keyPath, defaultBody, isPayloadMember)
                }
            }
            is StructureShape, is DocumentShape -> {
                writer.addImports(ctx.service.requestWireProtocol)
                addAggregateMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, writerSymbol, rootNodeInfo, payloadWritingClosure, keyPath, defaultBody, isPayloadMember)
            }
            is BlobShape -> {
                addBlobStreamMiddleware(writer, operationStackName, inputSymbol, outputSymbol, keyPath, isStreaming)
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

    private fun addAggregateMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, payloadSymbol: Symbol, writerSymbol: Symbol, rootNodeInfo: String, payloadWritingClosure: String, keyPath: String, defaultBody: String, isPayloadMember: Boolean) {
        if (isPayloadMember) {
            addPayloadBodyMiddleware(writer, operationStackName, inputSymbol, outputSymbol, payloadSymbol, writerSymbol, rootNodeInfo, payloadWritingClosure, keyPath, defaultBody)
        } else {
            addBodyMiddleware(writer, operationStackName, inputSymbol, outputSymbol, writerSymbol, rootNodeInfo, payloadWritingClosure)
        }
    }

    private fun addBodyMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, writerSymbol: Symbol, rootNodeInfo: String, payloadWritingClosure: String) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N>(rootNodeInfo: \$L, inputWritingClosure: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.BodyMiddleware,
            inputSymbol,
            outputSymbol,
            writerSymbol,
            rootNodeInfo,
            payloadWritingClosure,
        )
    }

    private fun addPayloadBodyMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, payloadSymbol: Symbol, writerSymbol: Symbol, rootNodeInfo: String, payloadWritingClosure: String, keyPath: String, defaultBody: String) {
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N, \$N>(rootNodeInfo: \$L, inputWritingClosure: \$L, keyPath: \$L, defaultBody: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.PayloadBodyMiddleware,
            inputSymbol,
            outputSymbol,
            payloadSymbol,
            writerSymbol,
            rootNodeInfo,
            payloadWritingClosure,
            keyPath,
            defaultBody
        )
    }

    private fun addEventStreamMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, payloadSymbol: Symbol, keyPath: String, defaultBody: String, requestWireProtocol: WireProtocol, sendInitialRequest: Boolean) {
        if (sendInitialRequest) {
            writer.write("let initialRequestMessage = try input.makeInitialRequestMessage(encoder: encoder)")
        }
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N>(keyPath: \$L, defaultBody: \$L, marshalClosure: \$N.marshal\$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.EventStreamBodyMiddleware,
            inputSymbol,
            outputSymbol,
            payloadSymbol,
            keyPath,
            defaultBody,
            payloadSymbol,
            if (sendInitialRequest) ", initialRequestMessage: initialRequestMessage" else ""
        )
    }

    private fun addBlobStreamMiddleware(writer: SwiftWriter, operationStackName: String, inputSymbol: Symbol, outputSymbol: Symbol, keyPath: String, streaming: Boolean) {
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
