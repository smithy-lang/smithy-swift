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

import java.util.logging.Logger
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolReference
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

/**
 * Checks to see if shape is in the body of the http request
 */
// TODO fix the edge case: a shape which is an operational input (i.e. has members bound to HTTP semantics) could be re-used elsewhere not as an operation input which means everything is in the body
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
        // render conformance to HttpRequestBinding for all input shapes
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
        // render init from HttpResponse for all output shapes
        val outputShapesWithHttpBindings: MutableSet<ShapeId> = mutableSetOf()
        for (operation in getHttpBindingOperations(ctx)) {
            if (operation.output.isPresent) {
                val outputShapeId = operation.output.get()
                if (outputShapesWithHttpBindings.contains(outputShapeId)) {
                    // The output shape is referenced by more than one operation
                    continue
                }
                renderInitOutputFromHttpResponse(ctx, operation)
                outputShapesWithHttpBindings.add(outputShapeId)
            }
        }

        //separate decodable conformance to nested types from output shapes
        //first loop through nested types and perform decodable implementation normally
        //then loop through output shapes and perform creation of body struct with decodable implementation
        val (structuresNeedingDecodableConformance, nestedStructuresNeedingDecodableConformance) = resolveStructuresNeedingDecodableConformance(ctx)
        // handle nested shapes normally
        for (structureShape in nestedStructuresNeedingDecodableConformance) {
            // conforming to Decodable and Coding Keys enum are rendered as separate extensions in separate files
            val structSymbol: Symbol = ctx.symbolProvider.toSymbol(structureShape)
            val rootNamespace = ctx.settings.moduleName

            val decodeSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${structSymbol.name}+Decodable.swift")
                .name(structSymbol.name)
                .build()
            ctx.delegator.useShapeWriter(decodeSymbol) { writer ->
                writer.openBlock("extension ${structSymbol.name}: Decodable {", "}") {
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
                    writer.addFoundationImport()
                    generateCodingKeysForStructure(ctx, writer, structureShape)
                    writer.write("") // need enter space between coding keys and decode implementation
                    StructDecodeGeneration(ctx, structureShape.members().toList(), writer, defaultTimestampFormat).render()
                }
            }
        }
        // handle top level output shapes which includes creating a new http body struct to handle deserialization
        for (structureShape in structuresNeedingDecodableConformance) {
            // conforming to Decodable and Coding Keys enum are rendered as separate extensions in separate files
            val structSymbol: Symbol = ctx.symbolProvider.toSymbol(structureShape)
            val rootNamespace = ctx.settings.moduleName
            val httpBodyMembers = structureShape.members().filter { it.isInHttpBody() }.toList()

            val decodeSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${structSymbol.name}Body+Decodable.swift")
                .name(structSymbol.name)
                .build()

            ctx.delegator.useShapeWriter(decodeSymbol) { writer ->
                writer.openBlock("struct ${structSymbol.name}Body {", "}") {
                    httpBodyMembers.forEach {
                        val memberSymbol = ctx.symbolProvider.toSymbol(it)
                        writer.write("public let \$L: \$T", it.memberName, memberSymbol)
                    }
                }
                writer.write("") // add space between struct declaration and decodable conformance
                writer.openBlock("extension ${structSymbol.name}Body: Decodable {", "}") {
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
                    writer.addFoundationImport()
                    generateCodingKeysForStructure(ctx, writer, structureShape)
                    writer.write("") // need enter space between coding keys and decode implementation
                    StructDecodeGeneration(ctx, httpBodyMembers, writer, defaultTimestampFormat).render()
                }
            }
        }
    }

    private fun renderInitOutputFromHttpResponse(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape) {
        if (op.output.isEmpty) {
            return
        }
        val opIndex = OperationIndex.of(ctx.model)
        val httpTrait = op.expectTrait(HttpTrait::class.java)
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(ctx.symbolProvider, opIndex, op)
        val outputShape = ctx.model.expectShape(op.output.get())
        val hasHttpBody = outputShape.members().filter { it.isInHttpBody() }.count() > 0
        val bindingIndex = HttpBindingIndex.of(ctx.model)
        val responseBindings = bindingIndex.getResponseBindings(op)
        val headerBindings = responseBindings.values
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val contentType = bindingIndex.determineResponseContentType(op, defaultContentType).orElse(defaultContentType)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$outputShapeName.swift")
            .name(outputShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
            writer.addFoundationImport()
            writer.openBlock("extension $outputShapeName {", "}") {
                writer.openBlock("public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {", "}") {
                    renderInitOutputComponentsFromHeaders(ctx, headerBindings, writer)
                    // prefix headers
                    // spec: "Only a single structure member can be bound to httpPrefixHeaders"
                    responseBindings.values.firstOrNull { it.location == HttpBinding.Location.PREFIX_HEADERS }
                        ?.let {
                            renderInitOutputComponentsFromPrefixHeaders(ctx, it, writer)
                        }
                    writer.write("")
                    renderInitOutputComponentsFromPayload(responseBindings, outputShapeName, writer)
                }
            }
            writer.write("")
        }
    }

    /**
     * Render initialization of all output members bound to a response header
     */
    private fun renderInitOutputComponentsFromHeaders(
        ctx: ProtocolGenerator.GenerationContext,
        bindings: List<HttpBinding>,
        writer: SwiftWriter
    ) {
        bindings.forEach { hdrBinding ->
            val memberTarget = ctx.model.expectShape(hdrBinding.member.target)
            val memberName = hdrBinding.member.memberName
            val headerName = hdrBinding.locationName
            writer.write("if let \$LHeaderValue = httpResponse.headers.value(for: \$S) {", memberName, headerName)
            writer.indent()
            when (memberTarget) {
                is NumberShape -> {
                    val memberValue = stringToNumber(memberTarget,
                        "${memberName}HeaderValue")
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is BlobShape -> {
                    val memberValue = "${memberName}HeaderValue.data(using: .utf8)"
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is BooleanShape -> {
                    val memberValue = "Bool(${memberName}HeaderValue)"
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is StringShape -> {
                    val memberValue: String
                    when {
                        memberTarget.hasTrait(EnumTrait::class.java) -> {
                            val enumSymbol = ctx.symbolProvider.toSymbol(memberTarget)
                            memberValue = "${enumSymbol.name}(rawValue: ${memberName}HeaderValue)"
                        }
                        memberTarget.hasTrait(MediaTypeTrait::class.java) -> {
                            memberValue = "try ${memberName}HeaderValue.base64EncodedString()"
                        }
                        else -> {
                            memberValue = "${memberName}HeaderValue"
                        }
                    }
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is TimestampShape -> {
                    val bindingIndex = HttpBindingIndex.of(ctx.model)
                    val tsFormat = bindingIndex.determineTimestampFormat(
                        hdrBinding.member,
                        HttpBinding.Location.HEADER,
                        defaultTimestampFormat)
                    var memberValue = doubleToDate("${memberName}HeaderValue", tsFormat)
                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) {
                        memberValue = doubleToDate("${memberName}HeaderValueDouble", tsFormat)
                        writer.write("if let \$LHeaderValueDouble = Double(\$LHeaderValue) {", memberName, memberName)
                        writer.indent()
                        writer.write("self.\$L = $memberValue", memberName)
                        writer.dedent()
                        writer.write("} else {")
                        writer.indent()
                        writer.write("throw ClientError.deserializationFailed(HeaderDeserializationError.invalidTimestampHeader(value: \$LHeaderValue))", memberName)
                        writer.dedent()
                        writer.write("}")
                    } else {
                        writer.write("self.\$L = $memberValue", memberName)
                    }
                }
                is CollectionShape -> {
                    // member > boolean, number, string, or timestamp
                    // headers are List<String>, get the internal mapping function contents (if any) to convert
                    // to the target symbol type

                    // we also have to handle multiple comma separated values (e.g. 'X-Foo': "1, 2, 3"`)
                    var splitFn = "splitHeaderListValues"
                    var splitFnPrefix = ""
                    var invalidHeaderListErrorName = "invalidNumbersHeaderList"
                    val conversion = when (val collectionMemberTarget = ctx.model.expectShape(memberTarget.member.target)) {
                        is BooleanShape -> {
                            invalidHeaderListErrorName = "invalidBooleanHeaderList"
                            "Bool(\$0)"
                        }
                        is NumberShape -> stringToNumber(collectionMemberTarget, "\$0")
                        is TimestampShape -> {
                            val bindingIndex = HttpBindingIndex.of(ctx.model)
                            val tsFormat = bindingIndex.determineTimestampFormat(
                                hdrBinding.member,
                                HttpBinding.Location.HEADER,
                                defaultTimestampFormat)
                            if (tsFormat == TimestampFormatTrait.Format.HTTP_DATE) {
                                splitFn = "splitHttpDateHeaderListValues"
                                splitFnPrefix = "try "
                            }
                            invalidHeaderListErrorName = "invalidTimestampHeaderList"
                            doubleToDate("\$0", tsFormat)
                        }
                        is StringShape -> {
                            invalidHeaderListErrorName = "invalidStringHeaderList"
                            when {
                                collectionMemberTarget.hasTrait(EnumTrait::class.java) -> {
                                    val enumSymbol = ctx.symbolProvider.toSymbol(collectionMemberTarget)
                                    "${enumSymbol.name}(rawValue: \$0)"
                                }
                                collectionMemberTarget.hasTrait(MediaTypeTrait::class.java) -> {
                                    "try \$0.base64EncodedString()"
                                }
                                else -> ""
                            }
                        }
                        else -> throw CodegenException("invalid member type for header collection: binding: $hdrBinding; member: $memberName")
                    }
                    val mapFn = if (conversion.isNotEmpty()) ".map { $conversion }" else ""
                    var memberValue = "${memberName}HeaderValues${mapFn}"
                    if (memberTarget.isSetShape) {
                        memberValue = "Set(${memberName}HeaderValues)"
                    }
                    writer.write("if let ${memberName}HeaderValues = $splitFnPrefix$splitFn(${memberName}HeaderValue) {")
                    writer.indent()
                    // render map function
                    val collectionMemberTargetShape = ctx.model.expectShape(memberTarget.member.target)
                    val collectionMemberTargetSymbol = ctx.symbolProvider.toSymbol(collectionMemberTargetShape)
                    if (!collectionMemberTargetSymbol.isBoxed()) {
                        writer.openBlock("self.\$L = try \$LHeaderValues.map {", "}", memberName, memberName) {
                            writer.openBlock("guard let \$LHeaderValueTransformed = \$L else {", "}", memberName, conversion) {
                                writer.write("throw ClientError.deserializationFailed(HeaderDeserializationError.\$L(value: \$LHeaderValue))", invalidHeaderListErrorName, memberName)
                            }
                        }

                    } else {
                        writer.write("self.\$L = \$L", memberName, memberValue)
                    }
                    writer.dedent()
                    writer.write("} else {")
                    writer.indent()
                    writer.write("self.\$L = nil", memberName)
                    writer.dedent()
                    writer.write("}")
                }
                else -> throw CodegenException("unknown deserialization: header binding: $hdrBinding; member: `$memberName`")
            }
            writer.dedent()
            writer.write("} else {")
            writer.indent()
            writer.write("self.\$L = nil", memberName)
            writer.dedent()
            writer.write("}")
        }
    }

    private fun renderInitOutputComponentsFromPrefixHeaders(
        ctx: ProtocolGenerator.GenerationContext,
        binding: HttpBinding,
        writer: SwiftWriter
    ) {
        // prefix headers MUST target string or collection-of-string
        val targetShape = ctx.model.expectShape(binding.member.target) as? MapShape
            ?: throw CodegenException("prefixHeader bindings can only be attached to Map shapes")

        val targetValueShape = ctx.model.expectShape(targetShape.value.target)
        val targetValueSymbol = ctx.symbolProvider.toSymbol(targetValueShape)
        val prefix = binding.locationName
        val memberName = binding.member.memberName

        val keyCollName = "keysFor${memberName.capitalize()}"
        val filter = if (prefix.isNotEmpty()) ".filter({ $0.starts(with: \"$prefix\") })" else ""

        writer.write("let $keyCollName = httpResponse.headers.dictionary.keys\$L", filter)
        writer.openBlock("if (!$keyCollName.isEmpty) {")
            .write("var mapMember = [String: ${targetValueSymbol.name}]()")
            .openBlock("for hdrKey in $keyCollName {")
            .call {
                val mapMemberValue = when (targetValueShape) {
                    is StringShape -> "httpResponse.headers.dictionary[hdrKey]?[0]"
                    is ListShape -> "httpResponse.headers.dictionary[hdrKey]"
                    is SetShape -> "Set(httpResponse.headers.dictionary[hdrKey])"
                    else -> throw CodegenException("invalid httpPrefixHeaders usage on ${binding.member}")
                }
                // get()/getAll() returns String? or List<String>?, this shouldn't ever trigger the continue though...
                writer.write("let mapMemberValue = $mapMemberValue")
                if (prefix.isNotEmpty()) {
                    writer.write("let mapMemberKey = hdrKey.removingPrefix(\$S)", prefix)
                    writer.write("mapMember[mapMemberKey] = mapMemberValue")
                } else {
                    writer.write("mapMember[hdrKey] = mapMemberValue")
                }
            }
            .closeBlock("}")
            .write("self.\$L = mapMember", memberName)
            .closeBlock("} else {")
        writer.indent()
        writer.write("self.\$L = nil", memberName)
        writer.dedent()
        writer.write("}")
    }

    private fun renderInitOutputComponentsFromPayload(
        responseBindings: Map<String, HttpBinding>,
        outputShapeName: String,
        writer: SwiftWriter
    ) {
        // document members
        // payload member(s)
        val bodyMembers: MutableList<String> = mutableListOf()
        val httpPayload = responseBindings.values.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            bodyMembers.add(httpPayload.member.memberName)
        } else {
            // Unbound document members that should be deserialized from the document format for the protocol.
            // The generated code is the same across protocols and the serialization provider instance
            // passed into the function is expected to handle the formatting required by the protocol
            val documentMembers = responseBindings.values
                .filter { it.location == HttpBinding.Location.DOCUMENT }
                .sortedBy { it.memberName }
                .map { it.member }

            if (documentMembers.isNotEmpty()) {
                documentMembers.forEach { member ->
                    bodyMembers.add(member.memberName)
                }
            }
        }

        // initialize body members
        if (bodyMembers.isNotEmpty()) {
            writer.write("if case .data(let data) = httpResponse.content,")
            writer.indent()
            writer.write("let unwrappedData = data,")
            writer.write("let responseDecoder = decoder {")
            writer.write("let output: ${outputShapeName}Body = try responseDecoder.decode(responseBody: unwrappedData)")
            bodyMembers.sorted().forEach {
                writer.write("self.$it = output.$it")
            }
            writer.dedent()
            writer.write("} else {")
            writer.indent()
            bodyMembers.sorted().forEach {
                writer.write("self.$it = nil")
            }
            writer.dedent()
            writer.write("}")
        }
    }

    // render conversion of string to appropriate number type
    internal fun stringToNumber(shape: NumberShape, wrappedValue: String): String = when (shape.type) {
        ShapeType.BYTE -> "Int8($wrappedValue)"
        ShapeType.SHORT -> "Int16($wrappedValue)"
        ShapeType.INTEGER -> "Int($wrappedValue)"
        ShapeType.LONG -> "Int($wrappedValue)"
        ShapeType.FLOAT -> "Float($wrappedValue)"
        ShapeType.DOUBLE -> "Double($wrappedValue)"
        else -> throw CodegenException("unknown number shape: $shape")
    }

    // render conversion of string to Date based on the timestamp format
    internal fun doubleToDate(wrappedValue: String, tsFmt: TimestampFormatTrait.Format): String = when (tsFmt) {
        TimestampFormatTrait.Format.EPOCH_SECONDS -> "Date(timeIntervalSince1970: $wrappedValue)"
        TimestampFormatTrait.Format.DATE_TIME -> "DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: $wrappedValue)"
        TimestampFormatTrait.Format.HTTP_DATE -> "DateFormatter.rfc5322DateFormatter.date(from: $wrappedValue)"
        else -> throw CodegenException("unknown timestamp format: $tsFmt")
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
    private fun resolveStructuresNeedingDecodableConformance(ctx: ProtocolGenerator.GenerationContext): Pair<Set<StructureShape>, Set<StructureShape>> {
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

        return Pair(outputShapes, nested)
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
        val opIndex = OperationIndex.of(ctx.model)
        val httpTrait = op.expectTrait(HttpTrait::class.java)
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(ctx.symbolProvider, opIndex, op)
        val inputShape = ctx.model.expectShape(op.input.get())
        val hasHttpBody = inputShape.members().filter { it.isInHttpBody() }.count() > 0
        val bindingIndex = HttpBindingIndex.of(ctx.model)
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
            writer.openBlock("extension $inputShapeName: HttpRequestBinding, Reflection {", "}") {
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

    private fun renderEncodedBodyAndReturn(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        inputShape: Shape,
        requestBindings: Map<String, HttpBinding>
    ) {
        val hasHttpBody = inputShape.members().filter { it.isInHttpBody() }.count() > 0
        val httpPayload = requestBindings.values.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }

        if (hasHttpBody) {
            var optionalTerminator = ""
            if (httpPayload != null) {
                val shape = ctx.model.expectShape(httpPayload.member.target)
                optionalTerminator = if (ctx.symbolProvider.toSymbol(shape).isBoxed()) "?" else ""
                renderExplicitPayload(ctx, httpPayload, writer)
            } else {
                writer.openBlock("if try !self.allPropertiesAreNull() {", "} else {") {
                    writer.write("let data = try encoder.encode(self)")
                    writer.write("let body = HttpBody.data(data)")
                    writer.write("headers.add(name: \"Content-Length\", value: String(data.count))")
                    writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)")
                }
                writer.indent()
                writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers)")
                writer.closeBlock("}")
            }
        } else {
            writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers)")
        }
    }

    private fun renderExplicitPayload(ctx: ProtocolGenerator.GenerationContext, binding: HttpBinding, writer: SwiftWriter) {
        // explicit payload member as the sole payload
        val memberName = binding.member.memberName
        val target = ctx.model.expectShape(binding.member.target)
        writer.openBlock("if let $memberName = self.$memberName {", "} else {") {
            when (target.type) {
                ShapeType.BLOB -> {
                    // FIXME handle streaming properly
                    val isBinaryStream =
                        ctx.model.getShape(binding.member.target).get().hasTrait(StreamingTrait::class.java)
                    writer.write("let data = \$L", memberName)
                    writer.write("let body = HttpBody.data(data)")
                }
                ShapeType.STRING -> {

                    val contents = if (target.hasTrait(EnumTrait::class.java)) {
                        "$memberName.rawValue"
                    } else {
                        memberName
                    }
                    writer.write("let data = \$L.data(using: .utf8)", contents)
                    writer.write("let body = HttpBody.data(data)")
                }
                ShapeType.STRUCTURE, ShapeType.UNION -> {
                    // delegate to the member encode function
                    writer.write("let data = try encoder.encode(\$L)", memberName)
                    writer.write("let body = HttpBody.data(data)")
                }
                ShapeType.DOCUMENT -> {
                    // TODO - deal with document members
                    writer.write("let data = try encoder.encode(\$L)", memberName)
                    writer.write("let body = HttpBody.data(data)")
                }
                else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
            }

            writer.write("headers.add(name: \"Content-Length\", value: String(data.count))")
            writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)")
        }
        writer.indent()
        writer.write("return HttpRequest(method: method, endpoint: endpoint, headers: headers)")
        writer.closeBlock("}")
    }

    private fun renderQueryItems(
        ctx: ProtocolGenerator.GenerationContext,
        queryLiterals: Map<String, String>,
        queryBindings: List<HttpBinding>,
        writer: SwiftWriter
    ) {
        writer.write("var queryItems: [URLQueryItem] = [URLQueryItem]()")
        queryLiterals.forEach { (queryItemKey, queryItemValue) ->
            val queryValue = if (queryItemValue.isBlank()) "nil" else "\"${queryItemValue}\""
            writer.write("queryItems.append(URLQueryItem(name: \$S, value: \$L))", queryItemKey, queryValue)
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
                    var queryItemValue = formatHeaderOrQueryValue(
                        ctx,
                        "queryItemValue",
                        memberTarget.member,
                        HttpBinding.Location.QUERY,
                        bindingIndex
                    )
                    val collectionMemberTargetShape = ctx.model.expectShape(memberTarget.member.target)
                    val collectionMemberTargetSymbol = ctx.symbolProvider.toSymbol(collectionMemberTargetShape)
                    writer.openBlock("$memberName.forEach { queryItemValue in ", "}") {
                        if (collectionMemberTargetSymbol.isBoxed()) {
                            writer.openBlock("if let unwrappedQueryItemValue = queryItemValue {", "}") {
                                queryItemValue = formatHeaderOrQueryValue(
                                    ctx,
                                    "unwrappedQueryItemValue",
                                    memberTarget.member,
                                    HttpBinding.Location.HEADER,
                                    bindingIndex
                                )
                                writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String(${queryItemValue}))")
                                writer.write("queryItems.append(queryItem)")
                            }
                        } else {
                            writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String(${queryItemValue}))")
                            writer.write("queryItems.append(queryItem)")
                        }
                    }
                } else {
                    memberName = formatHeaderOrQueryValue(
                        ctx,
                        memberName,
                        it.member,
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
        ctx: ProtocolGenerator.GenerationContext,
        memberName: String,
        memberShape: MemberShape,
        location: HttpBinding.Location,
        bindingIndex: HttpBindingIndex
    ): String {
        return when (val shape = ctx.model.expectShape(memberShape.target)) {
            is TimestampShape -> {
                val timestampFormat = bindingIndex.determineTimestampFormat(memberShape, location, defaultTimestampFormat)
                ProtocolGenerator.getFormattedDateString(timestampFormat, memberName, isInHeaderOrQuery = true)
            }
            is BlobShape -> {
                "try $memberName.base64EncodedString()"
            }
            is StringShape -> {
                val enumRawValueSuffix = shape.getTrait(EnumTrait::class.java).map { ".rawValue" }.orElse("")
                var formattedItemValue = "$memberName$enumRawValueSuffix"
                if (shape.hasTrait(MediaTypeTrait::class.java)) {
                    formattedItemValue = "try $formattedItemValue.base64EncodedString()"
                }
                formattedItemValue
            }
            else -> memberName
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
        // we only need the content type header in the request if there is an http body that is being sent
        if (hasHttpBody) {
            writer.write("headers.add(name: \"Content-Type\", value: \"$contentType\")")
        }
        headerBindings.forEach {
            val memberName = it.member.memberName
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName

            writer.openBlock("if let $memberName = $memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    var headerValue = formatHeaderOrQueryValue(
                        ctx,
                        "headerValue",
                        memberTarget.member,
                        HttpBinding.Location.HEADER,
                        bindingIndex
                    )
                    val collectionMemberTargetShape = ctx.model.expectShape(memberTarget.member.target)
                    val collectionMemberTargetSymbol = ctx.symbolProvider.toSymbol(collectionMemberTargetShape)
                    writer.openBlock("$memberName.forEach { headerValue in ", "}") {
                        if (collectionMemberTargetSymbol.isBoxed()) {
                            writer.openBlock("if let unwrappedHeaderValue = headerValue {", "}") {
                                headerValue = formatHeaderOrQueryValue(
                                    ctx,
                                    "unwrappedHeaderValue",
                                    memberTarget.member,
                                    HttpBinding.Location.HEADER,
                                    bindingIndex
                                )
                                writer.write("headers.add(name: \"$paramName\", value: String(${headerValue}))")
                            }
                        } else {
                            writer.write("headers.add(name: \"$paramName\", value: String(${headerValue}))")
                        }
                    }
                } else {
                    val memberNameWithExtension = formatHeaderOrQueryValue(
                        ctx,
                        memberName,
                        it.member,
                        HttpBinding.Location.HEADER,
                        bindingIndex
                    )
                    writer.write("headers.add(name: \"$paramName\", value: String($memberNameWithExtension))")
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
                val mapValueShapeTargetSymbol = ctx.symbolProvider.toSymbol(mapValueShapeTarget)

                writer.openBlock("for (prefixHeaderMapKey, prefixHeaderMapValue) in $memberName { ", "}") {
                    if (mapValueShapeTarget is CollectionShape) {
                        var headerValue = formatHeaderOrQueryValue(
                            ctx,
                            "headerValue",
                            mapValueShapeTarget.member,
                            HttpBinding.Location.HEADER,
                            bindingIndex
                        )
                        writer.openBlock("prefixHeaderMapValue.forEach { headerValue in ", "}") {
                            if (mapValueShapeTargetSymbol.isBoxed()) {
                                writer.openBlock("if let unwrappedHeaderValue = headerValue {", "}") {
                                    headerValue = formatHeaderOrQueryValue(
                                        ctx,
                                        "unwrappedHeaderValue",
                                        mapValueShapeTarget.member,
                                        HttpBinding.Location.HEADER,
                                        bindingIndex
                                    )
                                    writer.write("headers.add(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValue))")
                                }
                            } else {
                                writer.write("headers.add(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValue))")
                            }
                        }
                    } else {
                        var headerValue = formatHeaderOrQueryValue(
                            ctx,
                            "prefixHeaderMapValue",
                            it.member,
                            HttpBinding.Location.HEADER,
                            bindingIndex
                        )
                        if (mapValueShapeTargetSymbol.isBoxed()) {
                            writer.openBlock("if let unwrappedPrefixHeaderMapValue = prefixHeaderMapValue {", "}") {
                                headerValue = formatHeaderOrQueryValue(
                                    ctx,
                                    "unwrappedPrefixHeaderMapValue",
                                    it.member,
                                    HttpBinding.Location.HEADER,
                                    bindingIndex
                                )
                                writer.write("headers.add(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValue))")
                            }
                        } else {
                            writer.write("headers.add(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValue))")
                        }
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
                    "Unable to fetch $protocolName protocol request bindings for ${operation.id} because " +
                            "it does not have an http binding trait"
                )
            }
        }
        return containedOperations
    }
}
