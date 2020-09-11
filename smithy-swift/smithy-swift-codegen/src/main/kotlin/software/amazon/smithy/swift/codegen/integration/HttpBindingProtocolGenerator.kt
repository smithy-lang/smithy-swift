/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.CodegenException
import java.util.logging.Logger
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.neighbor.RelationshipType
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.*
import software.amazon.smithy.swift.codegen.*
import software.amazon.smithy.utils.OptionalUtils
import javax.swing.plaf.synth.SynthTreeUI

/**
 * Checks to see if shape is in the body of the http request
 */
//TODO fix the edge case: a shape which is an operational input (i.e. has members bound to HTTP semantics) could be re-used elsewhere not as an operation input which means everything is in the body
fun Shape.isInHttpBody(): Boolean {

    val hasNoHttpTraitsOutsideOfPayload = !this.hasTrait(HttpLabelTrait::class.java) &&
            !this.hasTrait(HttpHeaderTrait::class.java) &&
            !this.hasTrait(HttpPrefixHeadersTrait::class.java) &&
            !this.hasTrait(HttpQueryTrait::class.java)
    return this.hasTrait(HttpPayloadTrait::class.java) || hasNoHttpTraitsOutsideOfPayload
}

/**
 * Abstract implementation useful for all HTTP protocols
 */
abstract class HttpBindingProtocolGenerator : ProtocolGenerator {
    private val LOGGER = Logger.getLogger(javaClass.name)

    override fun generateSerializers(ctx: ProtocolGenerator.GenerationContext) {
        val inputShapesWithHttpBindings: MutableSet<ShapeId> = mutableSetOf()
        for (operation in getHttpBindingOperations(ctx)) {
            if (operation.input.isPresent) {
                val inputShapeId = operation.input.get()
                if (inputShapesWithHttpBindings.contains(inputShapeId)) {
                    // The input shape is referenced by more than one operation
                    continue
                }
                renderInputRequestConformanceToHttpRequestBinding(ctx, operation)
                inputShapesWithHttpBindings.add(inputShapeId)
            }
        }
        // render conformance to Encodable for all input shapes with an http body and their nested types
        val structuresNeedingEncodableConformance = resolveStructuresNeedingEncodableConformance(ctx)
        for (structureShape in structuresNeedingEncodableConformance) {
            // conforming to Encodable and Coding Keys enum are rendered as separate extensions in separate files
            val structSymbol: Symbol = ctx.symbolProvider.toSymbol(structureShape)
            val rootNamespace = ctx.settings.moduleName
            val encodeSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${structSymbol.name}+Encodable.swift")
                .name(structSymbol.name)
                .build()
            val httpBodyMembers = structureShape.members().filter { it.isInHttpBody() }.toList()
            ctx.delegator.useShapeWriter(encodeSymbol) { writer ->
                writer.openBlock("extension ${structSymbol.name}: Encodable {", "}") {
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
                    writer.addFoundationImport()
                    generateCodingKeysForStructure(ctx, writer, structureShape)
                    writer.write("") // need enter space between coding keys and encode implementation
                    StructEncodeGeneration(ctx, httpBodyMembers, writer, defaultTimestampFormat).render()
                }
            }
        }
    }
    // can be overridden by protocol for things like json name traits, xml keys etc.
    open fun generateCodingKeysForStructure(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        shape: StructureShape
    ) {
        // get all members sorted by name and filter out either all members with other traits OR members with the payload trait
        val membersSortedByName: List<MemberShape> = shape.allMembers.values
            .sortedBy { ctx.symbolProvider.toMemberName(it) }
            .filter { it.isInHttpBody() }
        writer.openBlock("private enum CodingKeys: String, CodingKey {", "}") {
            for (member in membersSortedByName) {
                val memberName = ctx.symbolProvider.toMemberName(member)
                writer.write("case $memberName")
            }
        }
    }

    override fun generateDeserializers(ctx: ProtocolGenerator.GenerationContext) {
        // render conformance to Decodable for all output shapes with an http body and their nested types
//        val structuresNeedingDecodableConformance = resolveStructuresNeedingDecodableConformance(ctx)
//        for (structureShape in structuresNeedingDecodableConformance) {
//            // conforming to Encodable and Coding Keys enum are rendered as separate extensions in separate files
//            val structSymbol: Symbol = ctx.symbolProvider.toSymbol(structureShape)
//            val rootNamespace = ctx.settings.moduleName
//            val encodeSymbol = Symbol.builder()
//                .definitionFile("./$rootNamespace/models/${structSymbol.name}+Decodable.swift")
//                .name(structSymbol.name)
//                .build()
//            val httpBodyMembers = structureShape.members().filter { it.isInHttpBody() }.toList()
//            ctx.delegator.useShapeWriter(structSymbol) { writer ->
//                writer.write("extension ${structSymbol.name}: Decodable {}")
////                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
////                    writer.addFoundationImport()
////                    generateCodingKeysForStructure(ctx, writer, structureShape)
////                    writer.write("") // need enter space between coding keys and decode implementation
//                    //TODO replace with full decode implementation in separate file
//               // }
//            }
//        }
    }

    /**
     * Find and return the set of shapes that need `Encodable` conformance which includes top level input types with members in the http body
     * and their nested types.
     * Operation inputs and all nested types will conform to `Encodable`.
     *
     * @return The set of shapes that require a `Encodable` conformance and coding keys.
     */
    private fun resolveStructuresNeedingEncodableConformance(ctx: ProtocolGenerator.GenerationContext): Set<StructureShape> {
        // all top level operation inputs with an http body must conform to Encodable
        // any structure shape that shows up as a nested member (direct or indirect) needs to also conform to Encodable
        // get them all and return as one set to loop through
        val inputShapes = resolveOperationInputShapes(ctx).filter { shapes -> shapes.members().any { it.isInHttpBody() } }.toMutableSet()

        val topLevelMembers = getHttpBindingOperations(ctx).flatMap {
            val inputShape = ctx.model.expectShape(it.input.get())
            inputShape.members()
            }
            .map { ctx.model.expectShape(it.target) }
            .filter { it.isStructureShape || it.isUnionShape || it is CollectionShape || it.isMapShape }
            .toSet()

        val nested = walkNestedShapesRequiringSerde(ctx, topLevelMembers)

        return inputShapes.plus(nested)
    }

    /**
     * Find and return the set of shapes that need `Decodable` conformance which includes top level outputs types with members returned in the http body
     * and their nested types.
     * Operation outputs and all nested types will conform to `Decodable`.
     *
     * @return The set of shapes that require a `Decodable` conformance and coding keys.
     */
    private fun resolveStructuresNeedingDecodableConformance(ctx: ProtocolGenerator.GenerationContext): Set<StructureShape> {
        // all top level operation outputs with an http body must conform to Decodable
        // any structure shape that shows up as a nested member (direct or indirect) needs to also conform to Decodable
        // get them all and return as one set to loop through
        val outputShapes = resolveOperationOutputShapes(ctx).filter { shapes -> shapes.members().any { it.isInHttpBody() } }.toMutableSet()

        val topLevelMembers = getHttpBindingOperations(ctx).flatMap {
            val outputShape = ctx.model.expectShape(it.output.get())
            outputShape.members()
            }
            .map { ctx.model.expectShape(it.target) }
            .filter { it.isStructureShape || it.isUnionShape || it is CollectionShape || it.isMapShape }
            .toSet()

        val nested = walkNestedShapesRequiringSerde(ctx, topLevelMembers)

        return outputShapes.plus(nested)
    }

    private fun resolveOperationInputShapes(ctx: ProtocolGenerator.GenerationContext): Set<StructureShape> {
        return getHttpBindingOperations(ctx).map { ctx.model.expectShape(it.input.get()) as StructureShape }.toSet()
    }

    private fun resolveOperationOutputShapes(ctx: ProtocolGenerator.GenerationContext): Set<StructureShape> {
        return getHttpBindingOperations(ctx).map { ctx.model.expectShape(it.output.get()) as StructureShape }.toSet()
    }

    private fun walkNestedShapesRequiringSerde(ctx: ProtocolGenerator.GenerationContext, shapes: Set<Shape>): Set<StructureShape> {
        val resolved = mutableSetOf<StructureShape>()
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
            }.forEach { walkedShape ->
                if (walkedShape.type == ShapeType.STRUCTURE) {
                    resolved.add(walkedShape as StructureShape)
                }
            }
        }
        return resolved
    }

    /**
     * Generate conformance to (HttpRequestBinding) for the input request (if not already present)
     * and implement (buildRequest) method
     */
    private fun renderInputRequestConformanceToHttpRequestBinding(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape
    ) {
        if (op.input.isEmpty) {
            return
        }
        val opIndex = ctx.model.getKnowledge(OperationIndex::class.java)
        val httpTrait = op.expectTrait(HttpTrait::class.java)
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(ctx.symbolProvider, opIndex, op)
        val inputShape = ctx.model.expectShape(op.input.get())
        val hasHttpBody = inputShape.members().filter { it.isInHttpBody() }.count() > 0
        val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
        val requestBindings = bindingIndex.getRequestBindings(op)
        val queryBindings = requestBindings.values.filter { it.location == HttpBinding.Location.QUERY }
        val queryLiterals = httpTrait.uri.queryLiterals
        val headerBindings = requestBindings.values
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val contentType = bindingIndex.determineRequestContentType(op, defaultContentType).orElse(defaultContentType)

        val prefixHeaderBindings = requestBindings.values
            .filter { it.location == HttpBinding.Location.PREFIX_HEADERS }

        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$inputShapeName+HttpRequestBinding.swift")
            .name(inputShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
            writer.addFoundationImport()
            writer.openBlock("extension $inputShapeName: HttpRequestBinding {", "}") {
                writer.openBlock(
                    "public func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder) throws -> HttpRequest {",
                    "}"
                ) {
                    renderQueryItems(ctx, queryLiterals, queryBindings, writer)
                    // TODO:: Replace host appropriately
                    writer.write("let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: path, queryItems: queryItems)")
                    renderHeaders(ctx, headerBindings, prefixHeaderBindings, writer, contentType, hasHttpBody)
                    renderEncodedBodyAndReturn(ctx, writer, inputShape, requestBindings)
                }
            }
            writer.write("")
        }
    }

    private fun renderEncodedBodyAndReturn(ctx: ProtocolGenerator.GenerationContext,
                                           writer: SwiftWriter,
                                           inputShape: Shape,
                                           requestBindings: Map<String,HttpBinding>) {
        val hasHttpBody = inputShape.members().filter { it.isInHttpBody() }.count() > 0
        val httpPayload = requestBindings.values.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }

        if(hasHttpBody) {
            if (httpPayload != null) {
                renderExplicitPayload(ctx, httpPayload, writer)
            } else {
                writer.write("let data = try encoder.encode(self)")
                writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers, body: HttpBody.data(data))")
            }
        } else {
            writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers)")
        }
    }

    private fun renderExplicitPayload(ctx: ProtocolGenerator.GenerationContext, binding: HttpBinding, writer: SwiftWriter) {
        // explicit payload member as the sole payload
        val memberName = binding.member.defaultName()

        val target = ctx.model.expectShape(binding.member.target)
        val name = target.camelCaseName()
        when (target.type) {
            ShapeType.BLOB -> {
                //FIXME handle streaming properly
                val isBinaryStream = ctx.model.getShape(binding.member.target).get().hasTrait(StreamingTrait::class.java)

                writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers, body: HttpBody.data(self.\$L))", name)
            }
            ShapeType.STRING -> {

                val contents = if (target.hasTrait(EnumTrait::class.java)) {
                    "$name.rawValue"
                } else {
                    name
                }
                writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers, body: HttpBody.data(self.\$L))", contents)
            }
            ShapeType.STRUCTURE, ShapeType.UNION -> {
                // delegate to the member encode function
                writer.write("let data = try encoder.encode(self.\$L)", name)
                writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers, body: HttpBody.data(data))")
            }
            ShapeType.DOCUMENT -> {
                // TODO - deal with document members
            }
            else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
        }
    }

    private fun renderQueryItems(
        ctx: ProtocolGenerator.GenerationContext,
        queryLiterals: Map<String, String>,
        queryBindings: List<HttpBinding>,
        writer: SwiftWriter
    ) {
        writer.write("var queryItems: [URLQueryItem] = [URLQueryItem]()")
        queryLiterals.forEach { (queryItemKey, queryItemValue) ->
            writer.write("queryItems.append(URLQueryItem(name: \$S, value: \$S))", queryItemKey, queryItemValue)
        }

        queryBindings.forEach {
            var memberName = it.member.memberName
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName
            val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)

            writer.openBlock("if let $memberName = $memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    // Handle cases where member is a List or Set type
                    val collectionMemberTarget = ctx.model.expectShape(memberTarget.member.target)
                    var queryItemValue = "queryItemValue"
                    queryItemValue = formatHeaderOrQueryValue(
                        queryItemValue,
                        collectionMemberTarget,
                        HttpBinding.Location.QUERY,
                        bindingIndex
                    )
                    writer.openBlock("$memberName.forEach { queryItemValue in ", "}") {
                        writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($queryItemValue))")
                        writer.write("queryItems.append(queryItem)")
                    }
                } else {
                    memberName = formatHeaderOrQueryValue(
                        memberName,
                        memberTarget,
                        HttpBinding.Location.QUERY,
                        bindingIndex
                    )
                    writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($memberName))")
                    writer.write("queryItems.append(queryItem)")
                }
            }
        }
    }

    private fun formatHeaderOrQueryValue(
        itemValue: String,
        itemShape: Shape,
        location: HttpBinding.Location,
        bindingIndex: HttpBindingIndex
    ): String {
        return when (itemShape) {
            is TimestampShape -> {
                val timestampFormat = bindingIndex.determineTimestampFormat(itemShape, location, defaultTimestampFormat)
                ProtocolGenerator.getFormattedDateString(timestampFormat, itemValue)
            }
            is BlobShape -> {
                "try $itemValue.base64EncodedString()"
            }
            is StringShape -> {
                val enumRawValueSuffix = itemShape.getTrait(EnumTrait::class.java).map { ".rawValue" }.orElse("")
                var formattedItemValue = "$itemValue$enumRawValueSuffix"
                if (itemShape.hasTrait(MediaTypeTrait::class.java)) {
                    formattedItemValue = "try $formattedItemValue.base64EncodedString()"
                }
                formattedItemValue
            }
            else -> itemValue
        }
    }

    private fun renderHeaders(
        ctx: ProtocolGenerator.GenerationContext,
        headerBindings: List<HttpBinding>,
        prefixHeaderBindings: List<HttpBinding>,
        writer: SwiftWriter,
        contentType: String,
        hasHttpBody: Boolean
    ) {
        val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
        writer.write("var headers = HttpHeaders()")
        //we only need the content type header in the request if there is an http body that is being sent
        if(hasHttpBody) {
            writer.write("headers.add(name: \"Content-Type\", value: \"$contentType\")")
        }
        headerBindings.forEach {
            var memberName = it.member.memberName
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName

            writer.openBlock("if let $memberName = $memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    val collectionMemberTarget = ctx.model.expectShape(memberTarget.member.target)
                    val headerValue = formatHeaderOrQueryValue(
                        "headerValue",
                        collectionMemberTarget,
                        HttpBinding.Location.HEADER,
                        bindingIndex
                    )
                    writer.openBlock("$memberName.forEach { headerValue in ", "}") {
                        writer.write("headers.add(name: \"$paramName\", value: String($headerValue))")
                    }
                } else {
                    memberName = formatHeaderOrQueryValue(
                        memberName,
                        memberTarget,
                        HttpBinding.Location.HEADER,
                        bindingIndex
                    )
                    writer.write("headers.add(name: \"$paramName\", value: String($memberName))")
                }
            }
        }

        prefixHeaderBindings.forEach {
            val memberName = it.member.memberName
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName

            writer.openBlock("if let $memberName = $memberName {", "}") {
                val mapValueShape = memberTarget.asMapShape().get().value
                val mapValueShapeTarget = ctx.model.expectShape(mapValueShape.target)

                writer.openBlock("for (prefixHeaderMapKey, prefixHeaderMapValue) in $memberName { ", "}") {
                    if (mapValueShapeTarget is CollectionShape) {
                        val collectionMemberTarget = ctx.model.expectShape(mapValueShapeTarget.member.target)
                        val headerValueString = formatHeaderOrQueryValue(
                            "headerValue",
                            collectionMemberTarget,
                            HttpBinding.Location.HEADER,
                            bindingIndex
                        )
                        writer.openBlock("prefixHeaderMapValue.forEach { headerValue in ", "}") {
                            writer.write("headers.add(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValueString))")
                        }
                    } else {
                        val headerValueString = formatHeaderOrQueryValue(
                            "prefixHeaderMapValue",
                            mapValueShapeTarget,
                            HttpBinding.Location.HEADER,
                            bindingIndex
                        )
                        writer.write("headers.add(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValueString))")
                    }
                }
            }
        }
    }

    override fun generateProtocolClient(ctx: ProtocolGenerator.GenerationContext) {
        val symbol = ctx.symbolProvider.toSymbol(ctx.service)
        ctx.delegator.useFileWriter("./${ctx.settings.moduleName}/${symbol.name}.swift") { writer ->
            val features = getHttpFeatures(ctx)
            HttpProtocolClientGenerator(ctx.model, ctx.symbolProvider, writer, ctx.service, features).render()
        }
    }

    /**
     * The default content-type when a document is synthesized in the body.
     */
    protected abstract val defaultContentType: String

    /**
     * The default format for timestamps.
     */
    protected abstract val defaultTimestampFormat: TimestampFormatTrait.Format

    /**
     * Get all of the features that are used as middleware
     */
    open fun getHttpFeatures(ctx: ProtocolGenerator.GenerationContext): List<HttpFeature> = listOf()

    /**
     * Get the operations with HTTP Bindings.
     *
     * @param ctx the generation context
     * @return the list of operation shapes
     */
    open fun getHttpBindingOperations(ctx: ProtocolGenerator.GenerationContext): List<OperationShape> {
        val topDownIndex: TopDownIndex = ctx.model.getKnowledge(TopDownIndex::class.java)
        val containedOperations: MutableList<OperationShape> = mutableListOf()
        for (operation in topDownIndex.getContainedOperations(ctx.service)) {
            OptionalUtils.ifPresentOrElse(
                operation.getTrait(HttpTrait::class.java),
                { containedOperations.add(operation) }
            ) {
                LOGGER.warning(
                    "Unable to fetch $protocol protocol request bindings for ${operation.id} because " +
                            "it does not have an http binding trait"
                )
            }
        }
        return containedOperations
    }
}
