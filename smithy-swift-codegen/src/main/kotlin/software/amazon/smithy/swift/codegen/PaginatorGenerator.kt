package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.PaginatedIndex
import software.amazon.smithy.model.knowledge.PaginationInfo
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.PaginatedTrait
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.SymbolProperty
import software.amazon.smithy.swift.codegen.model.camelCaseName
import software.amazon.smithy.swift.codegen.model.defaultName
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait

/**
 * Generate paginators for supporting operations.  See
 * https://awslabs.github.io/smithy/1.0/spec/core/behavior-traits.html#paginated-trait for details.
 */
class PaginatorGenerator : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean =
        model.operationShapes.any { it.hasTrait<PaginatedTrait>() }

    override fun writeAdditionalFiles(ctx: CodegenContext, delegator: SwiftDelegator) {
        val service = ctx.model.expectShape<ServiceShape>(ctx.settings.service)
        val paginatedIndex = PaginatedIndex.of(ctx.model)

        delegator.useFileWriter("Paginators.swift") { writer ->
            val paginatedOperations = service.allOperations
                .map { ctx.model.expectShape<OperationShape>(it) }
                .filter { operationShape -> operationShape.hasTrait(PaginatedTrait.ID) }

            paginatedOperations.forEach { paginatedOperation ->
                val paginationInfo = paginatedIndex.getPaginationInfo(service, paginatedOperation).getOrNull()
                    ?: throw CodegenException("Unexpectedly unable to get PaginationInfo from $service $paginatedOperation")
                val paginationItemInfo = getItemDescriptorOrNull(paginationInfo, ctx)

                renderPaginatorForOperation(writer, ctx, service, paginatedOperation, paginationInfo, paginationItemInfo)
            }
        }
    }

    // Render paginator(s) for operation
    private fun renderPaginatorForOperation(
        writer: SwiftWriter,
        ctx: CodegenContext,
        service: ServiceShape,
        paginatedOperation: OperationShape,
        paginationInfo: PaginationInfo,
        itemDesc: ItemDescriptor?
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
            cursorSymbol
        )

        // Optionally generate paginator when nested item is specified on the trait.
        if (itemDesc != null) {
            renderItemPaginator(
                writer,
                service,
                paginatedOperation,
                itemDesc,
                inputSymbol,
                outputSymbol
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
        cursorSymbol: Symbol
    ) {
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
        val nextMarkerLiteral = paginationInfo.outputTokenMemberPath.joinToString(separator = "?.") {
            it.defaultName()
        }
        val markerLiteral = paginationInfo.inputTokenMember.defaultName()

        val docBody = """
            Paginate over [${outputSymbol.name}] results.
            
            When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
            calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
            until then. If there are errors in your request, you will see the failures only after you start iterating.
            - Parameters: 
                - input: A [${inputSymbol.name}] to start pagination
            - Returns: An `AsyncSequence` that can iterate over `${outputSymbol.name}`
        """.trimIndent()
        writer.write("")
        writer.writeDocs(docBody)

        writer.openBlock("extension \$N {", "}", serviceSymbol) {
            writer.openBlock("func \$LPaginated(input: \$N) -> \$N<\$N, \$N> {", "}",
                operationShape.defaultName(),
                inputSymbol,
                ClientRuntimeTypes.Core.PaginatorSequence,
                inputSymbol,
                outputSymbol) {
                writer.write("return \$N<\$N, \$N>(input: input, inputKey: \\\$N.$markerLiteral, outputKey: \\\$N.$nextMarkerLiteral, paginationFunction: self.\$L(input:))",
                    ClientRuntimeTypes.Core.PaginatorSequence,
                    inputSymbol,
                    outputSymbol,
                    inputSymbol,
                    outputSymbol,
                    operationShape.defaultName())
            }
        }

        writer.write("")

        writer.openBlock("extension \$N: \$N {", "}", inputSymbol, ClientRuntimeTypes.Core.PaginateToken) {
            writer.openBlock("public func usingPaginationToken(_ input: String) -> \$N {", "}", inputSymbol) {
                writer.writeInline("return ")
                    .call {
                        val objectBuilder = Node.objectNodeBuilder()
                        val inputShape = model.expectShape(operationShape.input.get())
                        for (member in inputShape.members()) {
                            if (member.memberName != markerLiteral) {
                                objectBuilder.withMember(member.camelCaseName(), "self.${member.memberName}")
                            } else {
                                objectBuilder.withMember(member.camelCaseName(), "token")
                            }
                        }
                        println(inputShape)
                        println(objectBuilder.build())
                        ShapeValueGenerator(model, symbolProvider).writeShapeValueInline(
                            writer,
                            inputShape,
                            objectBuilder.build()
                        )
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
        writer.writeDocs(
            """
                This paginator transforms the `AsyncSequence` returned by [${operationShape.defaultName()}Paginated] 
                to access the nested member [${itemDesc.targetMember.defaultName(serviceShape)}]
                - Returns: [${itemDesc.targetMember.defaultName(serviceShape)}]`
            """.trimIndent()
        )

        writer.openBlock("extension PaginatorSequence where Input == \$N, Output == \$N {", "}", inputSymbol, outputSymbol) {
            writer.openBlock("func \$N() async throws -> [\$N] {", "}", itemDesc.itemLiteral, itemDesc.collectionLiteral) {
                writer.write("return try await self.asyncCompactMap { $0.\$N }", itemDesc.itemPathLiteral)
            }
        }
    }
}

/**
 * Model info necessary to codegen paginator item
 */
private data class ItemDescriptor(
    val collectionLiteral: String,
    val targetMember: Shape,
    val itemLiteral: String,
    val itemPathLiteral: String,
    val itemSymbol: Symbol
)

/**
 * Return an [ItemDescriptor] if model supplies, otherwise null
 */
private fun getItemDescriptorOrNull(paginationInfo: PaginationInfo, ctx: CodegenContext): ItemDescriptor? {
    val itemMemberId = paginationInfo.itemsMemberPath?.lastOrNull()?.target ?: return null

    val itemLiteral = paginationInfo.itemsMemberPath!!.last()!!.defaultName()
    val itemPathLiteral = paginationInfo.itemsMemberPath.joinToString(separator = "?.") { it.defaultName() }
    val itemMember = ctx.model.expectShape(itemMemberId)
    val (collectionLiteral, targetMember) = when (itemMember) {
        is MapShape ->
            ctx.symbolProvider.toSymbol(itemMember)
                .expectProperty(SymbolProperty.ENTRY_EXPRESSION) as String to itemMember
        is CollectionShape ->
            ctx.symbolProvider.toSymbol(ctx.model.expectShape(itemMember.member.target)).name to ctx.model.expectShape(
                itemMember.member.target
            )
        else -> error("Unexpected shape type ${itemMember.type}")
    }

    return ItemDescriptor(
        collectionLiteral,
        targetMember,
        itemLiteral,
        itemPathLiteral,
        ctx.symbolProvider.toSymbol(itemMember)
    )
}