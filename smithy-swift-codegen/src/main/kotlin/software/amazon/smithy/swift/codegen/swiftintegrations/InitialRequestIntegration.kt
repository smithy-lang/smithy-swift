package software.amazon.smithy.swift.codegen.swiftintegrations

import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.aws.traits.protocols.AwsJson1_1Trait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.EventStreamIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.NodeInfoUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WritingClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.struct.writerSymbol
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEventStreamsAPITypes

class InitialRequestIntegration : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        val service = settings.getService(model)
        return service.hasTrait<AwsJson1_0Trait>() || service.hasTrait<AwsJson1_1Trait>()
    }

    override fun writeAdditionalFiles(
        ctx: SwiftCodegenContext,
        protocolGenerationContext: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        val contentType: String = ctx.protocolGenerator?.defaultContentType ?: "application/json"
        val resolvedInputShapes = getOperationInputShapesWithStreamingUnionMember(protocolGenerationContext)
        resolvedInputShapes.forEach {
            val symbol: Symbol = ctx.symbolProvider.toSymbol(it)
            val rootNamespace = ctx.settings.moduleName
            val inputStruct = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${symbol.name}+MakeInitialRequestMessage.swift")
                .name(symbol.name)
                .build()
            protocolGenerationContext.delegator.useShapeWriter(inputStruct) { writer ->
                writer.apply {
                    addImport(protocolGenerationContext.service.writerSymbol.namespace)
                    openBlock("extension \$N {", "}", symbol) {
                        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                        openBlock(
                            "func makeInitialRequestMessage() throws -> \$N {",
                            "}",
                            SmithyEventStreamsAPITypes.Message,
                        ) {
                            val nodeInfoUtils = NodeInfoUtils(protocolGenerationContext, writer, protocolGenerationContext.service.requestWireProtocol)
                            val rootNodeInfo = nodeInfoUtils.nodeInfo(it, true)
                            val valueWritingClosure = WritingClosureUtils(protocolGenerationContext, writer).writingClosure(it)
                            writer.write("let writer = \$N(nodeInfo: \$L)", protocolGenerationContext.service.writerSymbol, rootNodeInfo)
                            writer.write("try writer.write(self, with: \$L)", valueWritingClosure)
                            writer.write("let initialRequestPayload = try writer.data()")
                            openBlock(
                                "let initialRequestMessage = \$N(",
                                ")",
                                SmithyEventStreamsAPITypes.Message,
                            ) {
                                openBlock(
                                    "headers: [",
                                    "],"
                                ) {
                                    write(
                                        "\$N(name: \":message-type\", value: .string(\"event\")),",
                                        SmithyEventStreamsAPITypes.Header,
                                    )
                                    write(
                                        "\$N(name: \":event-type\", value: .string(\"initial-request\")),",
                                        SmithyEventStreamsAPITypes.Header,
                                    )
                                    write(
                                        "\$N(name: \":content-type\", value: .string(\$S))",
                                        SmithyEventStreamsAPITypes.Header, contentType,
                                    )
                                }
                                write("payload: initialRequestPayload")
                            }
                            write("return initialRequestMessage")
                        }
                    }
                }
            }
        }
    }

    private fun getOperationInputShapesWithStreamingUnionMember(
        ctx: ProtocolGenerator.GenerationContext
    ): List<StructureShape> {
        var inputShapesWithStreamingUnion = ArrayList<StructureShape>()
        val eventStreamIndex = EventStreamIndex.of(ctx.model)
        TopDownIndex.of(ctx.model).getContainedOperations(ctx.service).forEach {
            eventStreamIndex.getInputInfo(it).ifPresent {
                inputShapesWithStreamingUnion.add(it.structure)
            }
        }
        return inputShapesWithStreamingUnion
    }
}
