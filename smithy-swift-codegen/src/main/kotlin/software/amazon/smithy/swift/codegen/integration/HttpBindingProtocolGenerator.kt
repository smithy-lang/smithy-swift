/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.neighbor.RelationshipType
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.IntEnumShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.HttpHeaderTrait
import software.amazon.smithy.model.traits.HttpLabelTrait
import software.amazon.smithy.model.traits.HttpPayloadTrait
import software.amazon.smithy.model.traits.HttpPrefixHeadersTrait
import software.amazon.smithy.model.traits.HttpQueryParamsTrait
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.model.traits.MediaTypeTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.codingKeys.CodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseGeneratable
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentLengthMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentMD5Middleware
import software.amazon.smithy.swift.codegen.integration.middlewares.ContentTypeMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.DeserializeMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.IdempotencyTokenMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.LoggingMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputBodyMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputHeadersMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputQueryItemMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputUrlHostMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.OperationInputUrlPathMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.RetryMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.HttpBodyMiddleware
import software.amazon.smithy.swift.codegen.integration.middlewares.providers.HttpHeaderProvider
import software.amazon.smithy.swift.codegen.integration.middlewares.providers.HttpQueryItemProvider
import software.amazon.smithy.swift.codegen.integration.middlewares.providers.HttpUrlPathProvider
import software.amazon.smithy.swift.codegen.integration.serde.DynamicNodeDecodingGeneratorStrategy
import software.amazon.smithy.swift.codegen.integration.serde.UnionDecodeGeneratorStrategy
import software.amazon.smithy.swift.codegen.integration.serde.UnionEncodeGeneratorStrategy
import software.amazon.smithy.swift.codegen.middleware.OperationMiddlewareGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata
import software.amazon.smithy.swift.codegen.model.bodySymbol
import software.amazon.smithy.utils.OptionalUtils
import java.util.Optional
import java.util.logging.Logger

/**
 * Checks to see if shape is in the body of the http request
 */
// TODO fix the edge case: a shape which is an operational input (i.e. has members bound to HTTP semantics) could be re-used elsewhere not as an operation input which means everything is in the body
fun Shape.isInHttpBody(): Boolean {
    val hasNoHttpTraitsOutsideOfPayload = !this.hasTrait(HttpLabelTrait::class.java) &&
        !this.hasTrait(HttpHeaderTrait::class.java) &&
        !this.hasTrait(HttpPrefixHeadersTrait::class.java) &&
        !this.hasTrait(HttpQueryTrait::class.java) &&
        !this.hasTrait(HttpQueryParamsTrait::class.java)
    return this.hasTrait(HttpPayloadTrait::class.java) || hasNoHttpTraitsOutsideOfPayload
}

/**
 * Adds the appropriate extension for serialization of special types i.e. timestamps, blobs, etc
 */
fun formatHeaderOrQueryValue(
    ctx: ProtocolGenerator.GenerationContext,
    memberName: String,
    memberShape: MemberShape,
    location: HttpBinding.Location,
    bindingIndex: HttpBindingIndex,
    defaultTimestampFormat: TimestampFormatTrait.Format
): Pair<String, Boolean> {

    return when (val shape = ctx.model.expectShape(memberShape.target)) {
        is TimestampShape -> {
            val timestampFormat = bindingIndex.determineTimestampFormat(memberShape, location, defaultTimestampFormat)
            Pair(ProtocolGenerator.getFormattedDateString(timestampFormat, memberName), false)
        }
        is BlobShape -> {
            Pair("try $memberName.base64EncodedString()", true)
        }
        is StringShape -> {
            val enumRawValueSuffix = shape.getTrait(EnumTrait::class.java).map { ".rawValue" }.orElse("")
            var formattedItemValue = "$memberName$enumRawValueSuffix"
            var requiresDoCatch = false
            if (shape.hasTrait(MediaTypeTrait::class.java)) {
                formattedItemValue = "try $formattedItemValue.base64EncodedString()"
                requiresDoCatch = true
            }
            Pair(formattedItemValue, requiresDoCatch)
        }
        is IntEnumShape -> Pair("$memberName.rawValue", false)
        else -> Pair(memberName, false)
    }
}

/**
 * Abstract implementation useful for all HTTP protocols
 */
abstract class HttpBindingProtocolGenerator : ProtocolGenerator {
    private val LOGGER = Logger.getLogger(javaClass.name)
    private val idempotencyTokenValue = "idempotencyTokenGenerator.generateToken()"

    override val unknownServiceErrorSymbol: Symbol = ClientRuntimeTypes.Http.UnknownHttpServiceError

    override var serviceErrorProtocolSymbol: Symbol = ClientRuntimeTypes.Http.HttpServiceError

    override fun generateSerializers(ctx: ProtocolGenerator.GenerationContext) {
        // render conformance to HttpRequestBinding for all input shapes
        val inputShapesWithHttpBindings: MutableSet<ShapeId> = mutableSetOf()
        for (operation in getHttpBindingOperations(ctx)) {
            if (operation.input.isPresent) {
                val inputShapeId = operation.input.get()
                if (inputShapesWithHttpBindings.contains(inputShapeId)) {
                    // The input shape is referenced by more than one operation
                    continue
                }
                val httpBindingResolver = getProtocolHttpBindingResolver(ctx, defaultContentType)
                HttpUrlPathProvider.renderUrlPathMiddleware(ctx, operation, httpBindingResolver)
                HttpHeaderProvider.renderHeaderMiddleware(ctx, operation, httpBindingResolver, defaultTimestampFormat)
                HttpQueryItemProvider.renderQueryMiddleware(ctx, operation, httpBindingResolver, defaultTimestampFormat)
                HttpBodyMiddleware.renderBodyMiddleware(ctx, operation, httpBindingResolver)
                inputShapesWithHttpBindings.add(inputShapeId)
            }
        }

        val inputShapesWithMetadata = resolveInputShapes(ctx)
        for ((shape, shapeMetadata) in inputShapesWithMetadata) {
            val symbol: Symbol = ctx.symbolProvider.toSymbol(shape)
            val symbolName = symbol.name
            val rootNamespace = ctx.settings.moduleName
            val encodeSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/$symbolName+Encodable.swift")
                .name(symbolName)
                .build()
            val httpBodyMembers = shape.members()
                .filter { it.isInHttpBody() }
                .toList()
            if (httpBodyMembers.isNotEmpty() || shouldRenderEncodableConformance) {
                ctx.delegator.useShapeWriter(encodeSymbol) { writer ->
                    writer.openBlock(
                        "extension $symbolName: \$N {",
                        "}",
                        SwiftTypes.Protocols.Encodable
                    ) {
                        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)

                        if (shouldRenderCodingKeysForEncodable) {
                            generateCodingKeysForMembers(ctx, writer, httpBodyMembers)
                            writer.write("")
                        }
                        renderStructEncode(ctx, shape, shapeMetadata, httpBodyMembers, writer, defaultTimestampFormat)
                    }
                }
            }
            if (shouldRenderDecodableBodyStructForInputShapes || httpBodyMembers.isNotEmpty()) {
                renderBodyStructAndDecodableExtension(ctx, shape, mapOf())
                DynamicNodeDecodingGeneratorStrategy(ctx, shape, isForBodyStruct = true).renderIfNeeded()
            }
        }
    }

    override fun generateDeserializers(ctx: ProtocolGenerator.GenerationContext) {
        val httpOperations = getHttpBindingOperations(ctx)
        val httpBindingResolver = getProtocolHttpBindingResolver(ctx, defaultContentType)
        httpResponseGenerator.render(ctx, httpOperations, httpBindingResolver)

        val outputShapesWithMetadata = resolveOutputShapes(ctx)

        for ((shape, metadata) in outputShapesWithMetadata) {
            if (shape.members().any { it.isInHttpBody() }) {
                renderBodyStructAndDecodableExtension(ctx, shape, metadata)
                DynamicNodeDecodingGeneratorStrategy(ctx, shape, isForBodyStruct = true).renderIfNeeded()
            }
        }

        val errorShapes = resolveErrorShapes(ctx)
        for (shape in errorShapes) {
            renderBodyStructAndDecodableExtension(ctx, shape, mapOf())
            DynamicNodeDecodingGeneratorStrategy(ctx, shape, isForBodyStruct = true).renderIfNeeded()
        }
    }

    override fun generateCodableConformanceForNestedTypes(ctx: ProtocolGenerator.GenerationContext) {
        val nestedShapes = resolveShapesNeedingCodableConformance(ctx)
        for (shape in nestedShapes) {
            renderCodableExtension(ctx, shape)
        }
    }

    private fun renderCodableExtension(ctx: ProtocolGenerator.GenerationContext, shape: Shape) {
        val symbol: Symbol = ctx.symbolProvider.toSymbol(shape)
        val symbolName = symbol.name
        val rootNamespace = ctx.settings.moduleName
        val encodeSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$symbolName+Codable.swift")
            .name(symbolName)
            .build()

        ctx.delegator.useShapeWriter(encodeSymbol) { writer ->
            writer.openBlock("extension \$N: \$N {", "}", symbol, SwiftTypes.Protocols.Codable) {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                val members = shape.members().toList()
                when (shape) {
                    is StructureShape -> {
                        // get all members sorted by name and filter out either all members with other traits OR members with the payload trait
                        val httpBodyMembers = members.filter { it.isInHttpBody() }
                        generateCodingKeysForMembers(ctx, writer, httpBodyMembers)
                        writer.write("")
                        renderStructEncode(ctx, shape, mapOf(), httpBodyMembers, writer, defaultTimestampFormat)
                        writer.write("")
                        renderStructDecode(ctx, mapOf(), httpBodyMembers, writer, defaultTimestampFormat)
                    }
                    is UnionShape -> {
                        // get all members of the union shape
                        val sdkUnknownMember = MemberShape.builder().id("${shape.id}\$sdkUnknown").target("smithy.api#String").build()
                        val unionMembersForCodingKeys = members.toMutableList()
                        unionMembersForCodingKeys.add(0, sdkUnknownMember)
                        generateCodingKeysForMembers(ctx, writer, unionMembersForCodingKeys)
                        writer.write("")
                        UnionEncodeGeneratorStrategy(ctx, members, writer, defaultTimestampFormat).render()
                        writer.write("")
                        UnionDecodeGeneratorStrategy(ctx, members, writer, defaultTimestampFormat).render()
                    }
                }
            }
        }
    }

    private fun renderBodyStructAndDecodableExtension(ctx: ProtocolGenerator.GenerationContext, shape: Shape, metadata: Map<ShapeMetadata, Any>) {
        val bodySymbol: Symbol = ctx.symbolProvider.toSymbol(shape).bodySymbol()
        val rootNamespace = ctx.settings.moduleName
        val httpBodyMembers = shape.members().filter { it.isInHttpBody() }.toList()

        val decodeSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/${bodySymbol.name}+Decodable.swift")
            .name(bodySymbol.name)
            .build()

        ctx.delegator.useShapeWriter(decodeSymbol) { writer ->
            writer.openBlock("struct ${decodeSymbol.name}: \$N {", "}", SwiftTypes.Protocols.Equatable) {
                httpBodyMembers.forEach {
                    val memberSymbol = ctx.symbolProvider.toSymbol(it)
                    writer.write("let \$L: \$T", ctx.symbolProvider.toMemberName(it), memberSymbol)
                }
            }
            writer.write("")
            writer.openBlock("extension ${decodeSymbol.name}: \$N {", "}", SwiftTypes.Protocols.Decodable) {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                generateCodingKeysForMembers(ctx, writer, httpBodyMembers)
                writer.write("")
                renderStructDecode(ctx, metadata, httpBodyMembers, writer, defaultTimestampFormat)
            }
        }
    }

    private fun generateCodingKeysForMembers(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        members: List<MemberShape>
    ) {
        codingKeysGenerator.generateCodingKeysForMembers(ctx, writer, members)
    }

    private fun resolveInputShapes(ctx: ProtocolGenerator.GenerationContext): Map<Shape, Map<ShapeMetadata, Any>> {
        var shapesInfo: MutableMap<Shape, Map<ShapeMetadata, Any>> = mutableMapOf()
        val operations = getHttpBindingOperations(ctx)
        for (operation in operations) {
            val inputType = ctx.model.expectShape(operation.input.get())
            var metadata = mapOf<ShapeMetadata, Any>(
                Pair(ShapeMetadata.OPERATION_SHAPE, operation),
                Pair(ShapeMetadata.SERVICE_VERSION, ctx.service.version)
            )
            shapesInfo.put(inputType, metadata)
        }
        return shapesInfo
    }

    private fun resolveOutputShapes(ctx: ProtocolGenerator.GenerationContext): Map<Shape, Map<ShapeMetadata, Any>> {
        var shapesInfo: MutableMap<Shape, Map<ShapeMetadata, Any>> = mutableMapOf()
        val operations = getHttpBindingOperations(ctx)
        for (operation in operations) {
            val outputType = ctx.model.expectShape(operation.output.get())
            var metadata = mapOf<ShapeMetadata, Any>(
                Pair(ShapeMetadata.OPERATION_SHAPE, operation),
            )
            shapesInfo.put(outputType, metadata)
        }
        return shapesInfo
    }

    private fun resolveErrorShapes(ctx: ProtocolGenerator.GenerationContext): Set<Shape> {
        val operationErrorShapes = getHttpBindingOperations(ctx)
            .flatMap { it.errors }
            .map { ctx.model.expectShape(it) }
            .toSet()
        return operationErrorShapes.filter { shapes -> shapes.members().any { it.isInHttpBody() } }.toMutableSet()
    }

    private fun resolveShapesNeedingCodableConformance(ctx: ProtocolGenerator.GenerationContext): Set<Shape> {

        val topLevelOutputMembers = getHttpBindingOperations(ctx).flatMap {
            val outputShape = ctx.model.expectShape(it.output.get())
            outputShape.members()
        }
            .map { ctx.model.expectShape(it.target) }
            .filter { it.isStructureShape || it.isUnionShape || it is CollectionShape || it.isMapShape }
            .toSet()

        val topLevelErrorMembers = getHttpBindingOperations(ctx)
            .flatMap { it.errors }
            .flatMap { ctx.model.expectShape(it).members() }
            .map { ctx.model.expectShape(it.target) }
            .filter { it.isStructureShape || it.isUnionShape || it is CollectionShape || it.isMapShape }
            .toSet()

        val topLevelInputMembers = getHttpBindingOperations(ctx).flatMap {
            val inputShape = ctx.model.expectShape(it.input.get())
            inputShape.members()
        }
            .map { ctx.model.expectShape(it.target) }
            .filter { it.isStructureShape || it.isUnionShape || it is CollectionShape || it.isMapShape }
            .toSet()

        val allTopLevelMembers = topLevelOutputMembers.union(topLevelErrorMembers).union(topLevelInputMembers)

        val nestedTypes = walkNestedShapesRequiringSerde(ctx, allTopLevelMembers)
        return nestedTypes
    }

    private fun walkNestedShapesRequiringSerde(ctx: ProtocolGenerator.GenerationContext, shapes: Set<Shape>): Set<Shape> {
        val resolved = mutableSetOf<Shape>()
        val walker = Walker(ctx.model)

        // walk all the shapes in the set and find all other
        // structs/unions (or collections thereof) in the graph from that shape
        shapes.forEach { shape ->
            walker.iterateShapes(shape) { relationship ->
                when (relationship.relationshipType) {
                    RelationshipType.MEMBER_TARGET,
                    RelationshipType.STRUCTURE_MEMBER,
                    RelationshipType.LIST_MEMBER,
                    RelationshipType.SET_MEMBER,
                    RelationshipType.MAP_VALUE,
                    RelationshipType.UNION_MEMBER -> true
                    else -> false
                }
            }.forEach {
                when (it) {
                    is UnionShape -> resolved.add(it)
                    is StructureShape -> resolved.add(it)
                }
            }
        }
        return resolved
    }

    override fun generateProtocolClient(ctx: ProtocolGenerator.GenerationContext) {
        val symbol = ctx.symbolProvider.toSymbol(ctx.service)
        ctx.delegator.useFileWriter("./${ctx.settings.moduleName}/${symbol.name}.swift") { writer ->
            val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
            val clientGenerator = httpProtocolClientGeneratorFactory.createHttpProtocolClientGenerator(
                ctx,
                getProtocolHttpBindingResolver(ctx, defaultContentType),
                writer,
                serviceSymbol.name,
                defaultContentType,
                httpProtocolCustomizable,
                operationMiddleware
            )
            clientGenerator.render()
        }
    }

    override fun initializeMiddleware(ctx: ProtocolGenerator.GenerationContext) {
        val resolver = getProtocolHttpBindingResolver(ctx, defaultContentType)
        for (operation in getHttpBindingOperations(ctx)) {
            operationMiddleware.appendMiddleware(operation, IdempotencyTokenMiddleware(ctx.model, ctx.symbolProvider))

            operationMiddleware.appendMiddleware(operation, ContentMD5Middleware(ctx.model, ctx.symbolProvider))
            operationMiddleware.appendMiddleware(operation, OperationInputUrlPathMiddleware(ctx.model, ctx.symbolProvider, ""))
            operationMiddleware.appendMiddleware(operation, OperationInputUrlHostMiddleware(ctx.model, ctx.symbolProvider, operation))
            operationMiddleware.appendMiddleware(operation, OperationInputHeadersMiddleware(ctx.model, ctx.symbolProvider))
            operationMiddleware.appendMiddleware(operation, OperationInputQueryItemMiddleware(ctx.model, ctx.symbolProvider))
            operationMiddleware.appendMiddleware(operation, ContentTypeMiddleware(ctx.model, ctx.symbolProvider, resolver.determineRequestContentType(operation)))
            operationMiddleware.appendMiddleware(operation, OperationInputBodyMiddleware(ctx.model, ctx.symbolProvider))

            operationMiddleware.appendMiddleware(operation, ContentLengthMiddleware(ctx.model, shouldRenderEncodableConformance))

            operationMiddleware.appendMiddleware(operation, DeserializeMiddleware(ctx.model, ctx.symbolProvider))
            operationMiddleware.appendMiddleware(operation, LoggingMiddleware(ctx.model, ctx.symbolProvider))
            operationMiddleware.appendMiddleware(operation, RetryMiddleware(ctx.model, ctx.symbolProvider))

            addProtocolSpecificMiddleware(ctx, operation)

            for (integration in ctx.integrations) {
                integration.customizeMiddleware(ctx, operation, operationMiddleware)
            }
        }
    }

    override val operationMiddleware = OperationMiddlewareGenerator()

    protected abstract val defaultTimestampFormat: TimestampFormatTrait.Format
    protected abstract val codingKeysGenerator: CodingKeysGenerator
    protected abstract val httpProtocolClientGeneratorFactory: HttpProtocolClientGeneratorFactory
    protected abstract val httpResponseGenerator: HttpResponseGeneratable
    protected abstract val shouldRenderDecodableBodyStructForInputShapes: Boolean
    protected abstract val shouldRenderCodingKeysForEncodable: Boolean
    protected abstract val shouldRenderEncodableConformance: Boolean
    protected abstract fun renderStructEncode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeContainingMembers: Shape,
        shapeMetaData: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format
    )
    protected abstract fun renderStructDecode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeMetaData: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format
    )
    protected abstract fun addProtocolSpecificMiddleware(ctx: ProtocolGenerator.GenerationContext, operation: OperationShape)

    /**
     * Get the operations with HTTP Bindings.
     *
     * @param ctx the generation context
     * @return the list of operation shapes
     */
    open fun getHttpBindingOperations(ctx: ProtocolGenerator.GenerationContext): List<OperationShape> {
        val topDownIndex: TopDownIndex = TopDownIndex.of(ctx.model)
        val containedOperations: MutableList<OperationShape> = mutableListOf()
        for (operation in topDownIndex.getContainedOperations(ctx.service)) {
            OptionalUtils.ifPresentOrElse(
                Optional.of(getProtocolHttpBindingResolver(ctx, defaultContentType).httpTrait(operation)::class.java),
                { containedOperations.add(operation) }
            ) {
                LOGGER.warning(
                    "Unable to fetch $protocolName protocol request bindings for ${operation.id} because " +
                        "it does not have an http binding trait"
                )
            }
        }
        return containedOperations
    }
}

class DefaultServiceConfig(writer: SwiftWriter, serviceName: String) : ServiceConfig(writer, serviceName)
