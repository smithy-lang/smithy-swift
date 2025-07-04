package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.PaginatedIndex
import software.amazon.smithy.model.knowledge.PaginationInfo
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.PaginatedTrait
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.customtraits.PaginationTruncationMember
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.SymbolProperty
import software.amazon.smithy.swift.codegen.model.defaultName
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

/**
 * Generate paginators for supporting operations.  See
 * https://smithy.io/2.0/spec/behavior-traits.html#smithy-api-paginated-trait for details.
 */
class PaginatorGenerator : SwiftIntegration {
    override fun enabledForService(
        model: Model,
        settings: SwiftSettings,
    ): Boolean = model.operationShapes.any { it.hasTrait<PaginatedTrait>() }

    override fun writeAdditionalFiles(
        ctx: SwiftCodegenContext,
        protoCtx: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator,
    ) {
        val service = ctx.model.expectShape<ServiceShape>(ctx.settings.service)
        val paginatedIndex = PaginatedIndex.of(ctx.model)

        val paginatedOperations =
            service.allOperations
                .map { ctx.model.expectShape<OperationShape>(it) }
                .filter { operationShape -> operationShape.hasTrait(PaginatedTrait.ID) }

        // Skip generating Paginators.swift if service has no paginated operations
        if (paginatedOperations.isEmpty()) {
            return
        }

        delegator.useFileWriter("Sources/${ctx.settings.moduleName}/Paginators.swift") { writer ->
            paginatedOperations.forEach { paginatedOperation ->
                val paginationInfo =
                    paginatedIndex.getPaginationInfo(service, paginatedOperation).orElse(null)
                        ?: throw CodegenException("Unexpectedly unable to get PaginationInfo from $service $paginatedOperation")
                val paginationItemInfo = getItemDescriptorOrNull(paginationInfo, ctx)
                renderPaginatorForOperation(writer, ctx, service, paginatedOperation, paginationInfo, paginationItemInfo)
            }
        }
    }

    // Render paginator(s) for operation
    private fun renderPaginatorForOperation(
        writer: SwiftWriter,
        ctx: SwiftCodegenContext,
        service: ServiceShape,
        paginatedOperation: OperationShape,
        paginationInfo: PaginationInfo,
        itemDesc: ItemDescriptor?,
    ) {
        val serviceSymbol = ctx.symbolProvider.toSymbol(service)
        val outputSymbol = ctx.symbolProvider.toSymbol(paginationInfo.output)
        val inputSymbol = ctx.symbolProvider.toSymbol(paginationInfo.input)
        val cursorMember = ctx.model.getShape(paginationInfo.inputTokenMember.target).get()
        val cursorSymbol = ctx.symbolProvider.toSymbol(cursorMember)

        renderResponsePaginator(
            writer,
            ctx.model,
            ctx.symbolProvider,
            serviceSymbol,
            paginatedOperation,
            inputSymbol,
            outputSymbol,
            paginationInfo,
            cursorSymbol,
        )

        // Optionally generate paginator when nested item is specified on the trait.
        if (itemDesc != null) {
            renderItemPaginator(
                writer,
                service,
                paginatedOperation,
                itemDesc,
                inputSymbol,
                outputSymbol,
            )
        }
    }

    // Generate the paginator that iterates over responses
    private fun renderResponsePaginator(
        writer: SwiftWriter,
        model: Model,
        symbolProvider: SymbolProvider,
        serviceSymbol: Symbol,
        operationShape: OperationShape,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        paginationInfo: PaginationInfo,
        cursorSymbol: Symbol,
    ) {
        val outputShape = paginationInfo.output

        val nextMarkerLiteral =
            paginationInfo.outputTokenMemberPath.joinToString(separator = "?.") {
                it.toLowerCamelCase()
            }
        val markerLiteral = paginationInfo.inputTokenMember.toLowerCamelCase()
        val markerLiteralShape = model.expectShape(paginationInfo.inputTokenMember.target)
        val markerLiteralSymbol = symbolProvider.toSymbol(markerLiteralShape)
        writer.openBlock("extension \$L {", "}", serviceSymbol.name) {
            val docBody =
                """
                Paginate over `[${outputSymbol.name}]` results.
                
                When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
                calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
                until then. If there are errors in your request, you will see the failures only after you start iterating.
                - Parameters: 
                    - input: A `[${inputSymbol.name}]` to start pagination
                - Returns: An `AsyncSequence` that can iterate over `${outputSymbol.name}`
                """.trimIndent()
            writer.writeSingleLineDocs {
                this.write(docBody)
            }
            writer.openBlock(
                "public func \$LPaginated(input: \$N) -> \$N<\$N, \$N> {",
                "}",
                operationShape.toLowerCamelCase(),
                inputSymbol,
                ClientRuntimeTypes.Core.PaginatorSequence,
                inputSymbol,
                outputSymbol,
            ) {
                val isTruncatedFlag =
                    outputShape
                        .members()
                        .firstOrNull { it.hasTrait(PaginationTruncationMember.ID) }
                        ?.defaultName()

                val isTruncatedPart = if (isTruncatedFlag != null) ", isTruncatedKey: \\.$isTruncatedFlag" else ""
                writer.write(
                    "return \$N<\$N, \$N>(input: input, inputKey: \\.$markerLiteral, outputKey: \\.$nextMarkerLiteral$isTruncatedPart, paginationFunction: self.\$L(input:))",
                    ClientRuntimeTypes.Core.PaginatorSequence,
                    inputSymbol,
                    outputSymbol,
                    operationShape.toLowerCamelCase(),
                )
            }
        }

        writer.write("")

        writer.openBlock("extension \$N: \$N {", "}", inputSymbol, ClientRuntimeTypes.Core.PaginateToken) {
            writer.openBlock("public func usingPaginationToken(_ token: \$N) -> \$N {", "}", markerLiteralSymbol, inputSymbol) {
                writer
                    .writeInline("return ")
                    .call {
                        val inputShape = model.expectShape(operationShape.input.get())
                        writer
                            .writeInline("\$N(", inputSymbol)
                            .indent()
                            .call {
                                val sortedMembers = inputShape.members().sortedBy { it.toLowerCamelCase() }
                                for ((index, member) in sortedMembers.withIndex()) {
                                    if (member.memberName.toLowerCamelCase() != markerLiteral) {
                                        writer.writeInline("\n\$L: \$L", member.toLowerCamelCase(), "self.${member.toLowerCamelCase()}")
                                    } else {
                                        writer.writeInline("\n\$L: \$L", member.toLowerCamelCase(), "token")
                                    }
                                    if (index < sortedMembers.size - 1) {
                                        writer.writeInline(",")
                                    }
                                }
                            }.dedent()
                            .writeInline("\n)")
                    }
            }
        }
    }

    // Generate a paginator that iterates over the model-specified item
    private fun renderItemPaginator(
        writer: SwiftWriter,
        serviceShape: ServiceShape,
        operationShape: OperationShape,
        itemDesc: ItemDescriptor,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
    ) {
        writer.write("")
        val itemSymbolShape = itemDesc.itemSymbol.getProperty("shape").orElse(null) as? Shape

        writer.openBlock(
            "extension PaginatorSequence where OperationStackInput == \$N, OperationStackOutput == \$N {",
            "}",
            inputSymbol,
            outputSymbol,
        ) {
            val docBody =
                """
                This paginator transforms the `AsyncSequence` returned by `${operationShape.toLowerCamelCase()}Paginated`
                to access the nested member `${itemDesc.collectionLiteral}`
                - Returns: `${itemDesc.collectionLiteral}`
                """.trimIndent()
            writer.writeSingleLineDocs {
                this.write(docBody)
            }
            writer.openBlock("public func \$L() async throws -> \$L {", "}", itemDesc.itemLiteral, itemDesc.collectionLiteral) {
                if (itemSymbolShape?.isListShape == true) {
                    writer.write("return try await self.asyncCompactMap { item in item.\$L }", itemDesc.itemPathLiteral)
                } else if (itemSymbolShape?.isMapShape == true) {
                    val suffix = if (itemDesc.itemSymbol.isBoxed()) "?" else ""
                    writer.write(
                        "return try await self.asyncCompactMap { item in item.\$L$suffix.map { (\$\$0, \$\$1) } }",
                        itemDesc.itemPathLiteral,
                    )
                } else {
                    error("Unexpected shape type $itemSymbolShape")
                }
            }
        }
    }
}

/**
 * Model info necessary to codegen paginator item
 */
private data class ItemDescriptor(
    val collectionLiteral: String,
    val itemLiteral: String,
    val itemPathLiteral: String,
    val itemSymbol: Symbol,
)

/**
 * Return an [ItemDescriptor] if model supplies, otherwise null
 */
private fun getItemDescriptorOrNull(
    paginationInfo: PaginationInfo,
    ctx: SwiftCodegenContext,
): ItemDescriptor? {
    val itemMemberId = paginationInfo.itemsMemberPath?.lastOrNull()?.target ?: return null
    val itemLiteral = paginationInfo.itemsMemberPath!!.last()!!.toLowerCamelCase()
    val itemPathLiteral = paginationInfo.itemsMemberPath.joinToString(separator = "?.") { it.toLowerCamelCase() }
    val itemMember = ctx.model.expectShape(itemMemberId)
    val collectionLiteral =
        when (itemMember) {
            is MapShape -> {
                val entryType = ctx.symbolProvider.toSymbol(itemMember).expectProperty(SymbolProperty.ENTRY_EXPRESSION) as String
                "[$entryType]"
            }
            is CollectionShape -> {
                ctx.symbolProvider.toSymbol(itemMember).fullName
            }
            else -> error("Unexpected shape type ${itemMember.type}")
        }

    return ItemDescriptor(
        collectionLiteral,
        itemLiteral,
        itemPathLiteral,
        ctx.symbolProvider.toSymbol(itemMember),
    )
}
