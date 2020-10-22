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

    // can be overridden by implementations to more specific error protocol
    override val unknownServiceErrorSymbol: Symbol = Symbol.builder()
        .name("UnknownHttpServiceError")
        .namespace(SwiftDependency.CLIENT_RUNTIME.namespace, "")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()

    override val serviceErrorProtocolSymbol: Symbol = Symbol.builder()
        .name("HttpServiceError")
        .namespace(SwiftDependency.CLIENT_RUNTIME.namespace, "")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()

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
        val shapesNeedingEncodableConformance = resolveShapesNeedingEncodableConformance(ctx)
        for (shape in shapesNeedingEncodableConformance) {
            // conforming to Encodable and Coding Keys enum are rendered as separate extensions in separate files
            val symbol: Symbol = ctx.symbolProvider.toSymbol(shape)
            val symbolName = symbol.name
            val rootNamespace = ctx.settings.moduleName
            val encodeSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/$symbolName+Encodable.swift")
                .name(symbolName)
                .build()

            ctx.delegator.useShapeWriter(encodeSymbol) { writer ->
                writer.openBlock("extension ${symbol.name}: Encodable {", "}") {
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
                    writer.addFoundationImport()
                    when (shape) {
                        is StructureShape -> {
                            // get all members sorted by name and filter out either all members with other traits OR members with the payload trait
                            val httpBodyMembers = shape.members()
                                .filter { it.isInHttpBody() }
                                .toList()
                            generateCodingKeysForMembers(ctx, writer, httpBodyMembers)
                            writer.write("") // need enter space between coding keys and encode implementation
                            StructEncodeGenerator(ctx, httpBodyMembers, writer, defaultTimestampFormat).render()
                        }
                        is UnionShape -> {
                            // get all members of the union shape
                            val unionMembers = shape.members().toMutableList()
                            val sdkUnknownMember = MemberShape.builder().id("${shape.id}\$sdkUnknown").target("smithy.api#String").build()
                            unionMembers.add(0, sdkUnknownMember)
                            generateCodingKeysForMembers(ctx, writer, unionMembers)
                            unionMembers.removeAt(0)
                            writer.write("") // need enter space between coding keys and encode implementation
                            UnionEncodeGenerator(ctx, unionMembers, writer, defaultTimestampFormat).render()
                        }
                    }
                }
            }
        }
    }

    // can be overridden by protocol for things like json name traits, xml keys etc.
    open fun generateCodingKeysForMembers(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        members: List<MemberShape>
    ) {
        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        writer.openBlock("private enum CodingKeys: String, CodingKey {", "}") {
            for (member in membersSortedByName) {
                val originalMemberName = member.memberName
                val modifiedMemberName = ctx.symbolProvider.toMemberName(member)

                /* If we have modified the member name to make it idiomatic to the language
                   like handling reserved keyword with appending an underscore or lowercasing the first letter,
                   we need to change the coding key accordingly so that during encoding and decoding, the modified member
                   name is transformed back to original name before it hits the service.
                 */
                if (originalMemberName == modifiedMemberName) {
                    writer.write("case \$L", modifiedMemberName)
                } else {
                    writer.write("case \$L = \$S", modifiedMemberName, originalMemberName)
                }
            }
        }
    }

    override fun generateDeserializers(ctx: ProtocolGenerator.GenerationContext) {
        // render init from HttpResponse for all output shapes
        val visitedOutputShapes: MutableSet<ShapeId> = mutableSetOf()
        for (operation in getHttpBindingOperations(ctx)) {
            if (operation.output.isPresent) {
                val outputShapeId = operation.output.get()
                if (visitedOutputShapes.contains(outputShapeId)) {
                    // The output shape is referenced by more than one operation
                    continue
                }
                renderInitOutputFromHttpResponse(ctx, operation)
                visitedOutputShapes.add(outputShapeId)
            }
        }

        // render operation error enum initializer from HttpResponse for all operations
        val httpOperations = getHttpBindingOperations(ctx)
        httpOperations.forEach {
            renderInitOperationErrorFromErrorType(ctx, it)
            renderInitOperationErrorFromHttpResponse(ctx, it)
        }

        // render init from HttpResponse for all error types
        val modeledErrors = httpOperations.flatMap { it.errors }.map { ctx.model.expectShape(it) as StructureShape }.toSet()
        modeledErrors.forEach { renderInitErrorFromHttpResponse(ctx, it) }

        // separate decodable conformance to nested types from output shapes
        // first loop through nested types and perform decodable implementation normally
        // then loop through output shapes and perform creation of body struct with decodable implementation
        val (shapesNeedingDecodableConformance, nestedShapesNeedingDecodableConformance) = resolveShapesNeedingDecodableConformance(ctx)
        // handle nested shapes normally
        for (shape in nestedShapesNeedingDecodableConformance) {
            // conforming to Decodable and Coding Keys enum are rendered as separate extensions in separate files
            val symbol: Symbol = ctx.symbolProvider.toSymbol(shape)
            val symbolName = symbol.name
            val rootNamespace = ctx.settings.moduleName
            val decodeSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/$symbolName+Decodable.swift")
                .name(symbolName)
                .build()

            ctx.delegator.useShapeWriter(decodeSymbol) { writer ->
                writer.openBlock("extension $symbolName: Decodable {", "}") {
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
                    writer.addFoundationImport()
                    val members = shape.members().toMutableList()
                    when (shape) {
                        is StructureShape -> {
                            generateCodingKeysForMembers(ctx, writer, members)
                            writer.write("")
                            StructDecodeGenerator(ctx, members, writer, defaultTimestampFormat).render()
                        }
                        is UnionShape -> {
                            val sdkUnknownMember = MemberShape.builder().id("${shape.id}\$sdkUnknown").target("smithy.api#String").build()
                            members.add(0, sdkUnknownMember)
                            generateCodingKeysForMembers(ctx, writer, members)
                            writer.write("")
                            members.removeAt(0)
                            UnionDecodeGenerator(ctx, members, writer, defaultTimestampFormat).render()
                        }
                    }
                }
            }
        }

        // handle top level output shapes which includes creating a new http body struct to handle deserialization
        for (shape in shapesNeedingDecodableConformance) {
            // conforming to Decodable and Coding Keys enum are rendered as separate extensions in separate files
            val structSymbol: Symbol = ctx.symbolProvider.toSymbol(shape)
            val rootNamespace = ctx.settings.moduleName
            val httpBodyMembers = shape.members().filter { it.isInHttpBody() }.toList()

            val decodeSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${structSymbol.name}Body+Decodable.swift")
                .name(structSymbol.name)
                .build()

            ctx.delegator.useShapeWriter(decodeSymbol) { writer ->
                writer.openBlock("struct ${structSymbol.name}Body {", "}") {
                    httpBodyMembers.forEach {
                        val memberSymbol = ctx.symbolProvider.toSymbol(it)
                        writer.write("public let \$L: \$T", ctx.symbolProvider.toMemberName(it), memberSymbol)
                    }
                }
                writer.write("") // add space between struct declaration and decodable conformance
                writer.openBlock("extension ${structSymbol.name}Body: Decodable {", "}") {
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
                    writer.addFoundationImport()
                    generateCodingKeysForMembers(ctx, writer, httpBodyMembers)
                    writer.write("") // need enter space between coding keys and decode implementation
                    StructDecodeGenerator(ctx, httpBodyMembers, writer, defaultTimestampFormat).render()
                }
            }
        }
    }

    private fun renderInitOutputFromHttpResponse(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape
    ) {
        if (op.output.isEmpty) {
            return
        }
        val opIndex = OperationIndex.of(ctx.model)
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(ctx.symbolProvider, opIndex, op)
        val bindingIndex = HttpBindingIndex.of(ctx.model)
        val responseBindings = bindingIndex.getResponseBindings(op)
        val headerBindings = responseBindings.values
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$outputShapeName+ResponseInit.swift")
            .name(outputShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
            writer.addFoundationImport()
            writer.openBlock("extension $outputShapeName {", "}") {
                writer.openBlock("public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {", "}") {
                    renderInitMembersFromHeaders(ctx, headerBindings, writer)
                    // prefix headers
                    // spec: "Only a single structure member can be bound to httpPrefixHeaders"
                    responseBindings.values.firstOrNull { it.location == HttpBinding.Location.PREFIX_HEADERS }
                        ?.let {
                            renderInitMembersFromPrefixHeaders(ctx, it, writer)
                        }
                    writer.write("")
                    renderInitMembersFromPayload(ctx, responseBindings, outputShapeName, writer)
                }
            }
            writer.write("")
        }
    }

    private fun renderInitErrorFromHttpResponse(
        ctx: ProtocolGenerator.GenerationContext,
        shape: StructureShape
    ) {
        val bindingIndex = HttpBindingIndex.of(ctx.model)
        val responseBindings = bindingIndex.getResponseBindings(shape)
        val headerBindings = responseBindings.values
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val errorShapeName = ctx.symbolProvider.toSymbol(shape).name

        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$errorShapeName+ResponseInit.swift")
            .name(errorShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
            writer.addImport(serviceErrorProtocolSymbol)
            writer.openBlock("extension \$L: \$L {", "}", errorShapeName, serviceErrorProtocolSymbol.name) {
                writer.openBlock("public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil, message: String? = nil, requestID: String? = nil) throws {", "}") {
                    renderInitMembersFromHeaders(ctx, headerBindings, writer)
                    // prefix headers
                    // spec: "Only a single structure member can be bound to httpPrefixHeaders"
                    responseBindings.values.firstOrNull { it.location == HttpBinding.Location.PREFIX_HEADERS }
                        ?.let {
                            renderInitMembersFromPrefixHeaders(ctx, it, writer)
                        }
                    writer.write("")
                    renderInitMembersFromPayload(ctx, responseBindings, errorShapeName, writer)
                    writer.write("")
                    writer.write("self._headers = httpResponse.headers")
                    writer.write("self._statusCode = httpResponse.statusCode")
                    writer.write("self._requestID = requestID")
                    writer.write("self._message = message")
                }
            }
            writer.write("")
        }
    }

    // Initialize operation error given the errorType which is like a rawValue of error case encountered
    private fun renderInitOperationErrorFromErrorType(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape
    ) {
        val errorShapes = op.errors.map { ctx.model.expectShape(it) as StructureShape }.toSet().sorted()
        val operationErrorName = ServiceGenerator.getOperationErrorShapeName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+ResponseInit.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
            writer.addImport(unknownServiceErrorSymbol)
            val unknownServiceErrorType = unknownServiceErrorSymbol.name

            writer.openBlock("extension \$L {", "}", operationErrorName) {
                writer.openBlock("public init(errorType: String?, httpResponse: HttpResponse, decoder: ResponseDecoder? = nil, message: String? = nil, requestID: String? = nil) throws {", "}") {
                    writer.write("switch errorType {")
                    for (errorShape in errorShapes) {
                        val errorShapeName = ctx.symbolProvider.toSymbol(errorShape).name
                        writer.write("case \$S : self = .\$L(try \$L(httpResponse: httpResponse, decoder: decoder, message: message, requestID: requestID))", errorShapeName, errorShapeName.decapitalize(), errorShapeName)
                    }
                    writer.write("default : self = .unknown($unknownServiceErrorType(httpResponse: httpResponse, message: message))")
                    writer.write("}")
                }
            }
        }
    }

    /* This is a default implementation that is expected to be overridden by serialization
    protocol specific implementations to resolve the errorType
     */
    open fun renderInitOperationErrorFromHttpResponse(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape
    ) {
        val operationErrorName = ServiceGenerator.getOperationErrorShapeName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+ResponseInit.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
            writer.openBlock("extension \$L {", "}", operationErrorName) {
                writer.openBlock("public init(httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {", "}") {
                    writer.write("throw ClientError.deserializationFailed(ClientError.dataNotFound(\"Invalid information in current codegen context to resolve the ErrorType\"))")
                }
            }
        }
    }

    /**
     * Render initialization of all output members bound to a response header
     */
    private fun renderInitMembersFromHeaders(
        ctx: ProtocolGenerator.GenerationContext,
        bindings: List<HttpBinding>,
        writer: SwiftWriter
    ) {
        bindings.forEach { hdrBinding ->
            val memberTarget = ctx.model.expectShape(hdrBinding.member.target)
            val memberName = ctx.symbolProvider.toMemberName(hdrBinding.member)
            val headerName = hdrBinding.locationName
            val headerDeclaration = "${memberName}HeaderValue"
            writer.write("if let $headerDeclaration = httpResponse.headers.value(for: \$S) {", headerName)
            writer.indent()
            when (memberTarget) {
                is NumberShape -> {
                    val memberValue = stringToNumber(memberTarget, headerDeclaration)
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is BlobShape -> {
                    val memberValue = "$headerDeclaration.data(using: .utf8)"
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is BooleanShape -> {
                    val memberValue = "Bool($headerDeclaration)"
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is StringShape -> {
                    val memberValue = when {
                        memberTarget.hasTrait(EnumTrait::class.java) -> {
                            val enumSymbol = ctx.symbolProvider.toSymbol(memberTarget)
                            "${enumSymbol.name}(rawValue: $headerDeclaration)"
                        }
                        memberTarget.hasTrait(MediaTypeTrait::class.java) -> {
                            "try $headerDeclaration.base64DecodedString()"
                        }
                        else -> {
                            headerDeclaration
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
                    var memberValue = stringToDate(headerDeclaration, tsFormat)
                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) {
                        memberValue = stringToDate("${headerDeclaration}Double", tsFormat)
                        writer.write("if let ${headerDeclaration}Double = Double(\$LHeaderValue) {", memberName)
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
                            stringToDate("\$0", tsFormat)
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
                    var memberValue = "${memberName}HeaderValues$mapFn"
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
                            val transformedHeaderDeclaration = "${memberName}Transformed"
                            writer.openBlock("guard let \$L = \$L else {", "}", transformedHeaderDeclaration, conversion) {
                                writer.write("throw ClientError.deserializationFailed(HeaderDeserializationError.\$L(value: \$LHeaderValue))", invalidHeaderListErrorName, memberName)
                            }
                            writer.write("return \$L", transformedHeaderDeclaration)
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

    private fun renderInitMembersFromPrefixHeaders(
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
        val memberName = ctx.symbolProvider.toMemberName(binding.member)

        val keyCollName = "keysFor${memberName.capitalize()}"
        val filter = if (prefix.isNotEmpty()) ".filter({ $0.starts(with: \"$prefix\") })" else ""

        writer.write("let $keyCollName = httpResponse.headers.dictionary.keys\$L", filter)
        writer.openBlock("if (!$keyCollName.isEmpty) {")
            .write("var mapMember = [String: ${targetValueSymbol.name}]()")
            .openBlock("for headerKey in $keyCollName {")
            .call {
                val mapMemberValue = when (targetValueShape) {
                    is StringShape -> "httpResponse.headers.dictionary[headerKey]?[0]"
                    is ListShape -> "httpResponse.headers.dictionary[headerKey]"
                    is SetShape -> "Set(httpResponse.headers.dictionary[headerKey])"
                    else -> throw CodegenException("invalid httpPrefixHeaders usage on ${binding.member}")
                }
                // get()/getAll() returns String? or List<String>?, this shouldn't ever trigger the continue though...
                writer.write("let mapMemberValue = $mapMemberValue")
                if (prefix.isNotEmpty()) {
                    writer.write("let mapMemberKey = headerKey.removePrefix(\$S)", prefix)
                    writer.write("mapMember[mapMemberKey] = mapMemberValue")
                } else {
                    writer.write("mapMember[headerKey] = mapMemberValue")
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

    private fun renderInitMembersFromPayload(
        ctx: ProtocolGenerator.GenerationContext,
        responseBindings: Map<String, HttpBinding>,
        outputShapeName: String,
        writer: SwiftWriter
    ) {
        var queryMemberNames = responseBindings.values
                .filter { it.location == HttpBinding.Location.QUERY }
                .sortedBy { it.memberName }
                .map { ctx.symbolProvider.toMemberName(it.member) }.toMutableSet()

        val httpPayload = responseBindings.values.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            renderDeserializeExplicitPayload(ctx, httpPayload, writer)
        } else {
            // Unbound document members that should be deserialized from the document format for the protocol.
            // The generated code is the same across protocols and the serialization provider instance
            // passed into the function is expected to handle the formatting required by the protocol
            val bodyMembers = responseBindings.values
                .filter { it.location == HttpBinding.Location.DOCUMENT }

            queryMemberNames = queryMemberNames.union(
                bodyMembers
                    .filter { it.member.hasTrait(HttpQueryTrait::class.java) }
                    .map { ctx.symbolProvider.toMemberName(it.member) }
                    .toMutableSet()
            ).toMutableSet()

            val bodyMemberNames = bodyMembers
                .filter { !it.member.hasTrait(HttpQueryTrait::class.java) }
                .map { ctx.symbolProvider.toMemberName(it.member) }.toMutableSet()

            if (bodyMemberNames.isNotEmpty()) {
                writer.write("if case .data(let data) = httpResponse.content,")
                writer.indent()
                writer.write("let unwrappedData = data,")
                writer.write("let responseDecoder = decoder {")
                writer.write("let output: ${outputShapeName}Body = try responseDecoder.decode(responseBody: unwrappedData)")
                bodyMemberNames.sorted().forEach {
                    writer.write("self.$it = output.$it")
                }
                writer.dedent()
                writer.write("} else {")
                writer.indent()
                bodyMemberNames.sorted().forEach {
                    writer.write("self.$it = nil")
                }
                writer.dedent()
                writer.write("}")
            }
        }

        // initialize query members
        queryMemberNames.sorted().forEach {
            writer.write("self.$it = nil")
        }
    }

    private fun renderDeserializeExplicitPayload(ctx: ProtocolGenerator.GenerationContext, binding: HttpBinding, writer: SwiftWriter) {
        val memberName = ctx.symbolProvider.toMemberName(binding.member)
        val target = ctx.model.expectShape(binding.member.target)
        val symbol = ctx.symbolProvider.toSymbol(target)
        writer.openBlock("if case .data(let data) = httpResponse.content,\n   let unwrappedData = data {", "} else {") {
            when (target.type) {
                ShapeType.DOCUMENT -> {
                    // TODO deal with document type
                    writer.write("self.\$L = nil", memberName)
                }
                ShapeType.STRING -> {
                    writer.openBlock("if let responseDecoder = decoder {", "} else {") {
                        writer.write(
                            "let output: \$L = try responseDecoder.decode(responseBody: unwrappedData)",
                            symbol
                        )
                        writer.write("self.\$L = output", memberName)
                    }
                    writer.indent()
                    writer.write("self.\$L = nil", memberName).closeBlock("}")
                }
                ShapeType.BLOB -> {
                    writer.write("self.\$L = unwrappedData", memberName)
                }
                ShapeType.STRUCTURE, ShapeType.UNION -> {
                    writer.openBlock("if let responseDecoder = decoder {", "} else {") {
                        writer.write(
                            "let output: \$L = try responseDecoder.decode(responseBody: unwrappedData)",
                            symbol
                        )
                        writer.write("self.\$L = output", memberName)
                    }
                    writer.indent()
                    writer.write("self.\$L = nil", memberName).closeBlock("}")
                }
                else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
            }
        }
        writer.indent()
        writer.write("self.\$L = nil", memberName).closeBlock("}")
    }

    // render conversion of string to appropriate number type
    internal fun stringToNumber(shape: NumberShape, stringValue: String): String = when (shape.type) {
        ShapeType.BYTE -> "Int8($stringValue)"
        ShapeType.SHORT -> "Int16($stringValue)"
        ShapeType.INTEGER -> "Int($stringValue)"
        ShapeType.LONG -> "Int($stringValue)"
        ShapeType.FLOAT -> "Float($stringValue)"
        ShapeType.DOUBLE -> "Double($stringValue)"
        else -> throw CodegenException("unknown number shape: $shape")
    }

    // render conversion of string to Date based on the timestamp format
    private fun stringToDate(stringValue: String, tsFmt: TimestampFormatTrait.Format): String = when (tsFmt) {
        TimestampFormatTrait.Format.EPOCH_SECONDS -> "Date(timeIntervalSince1970: $stringValue)"
        TimestampFormatTrait.Format.DATE_TIME -> "DateFormatter.iso8601DateFormatterWithoutFractionalSeconds.date(from: $stringValue)"
        TimestampFormatTrait.Format.HTTP_DATE -> "DateFormatter.rfc5322DateFormatter.date(from: $stringValue)"
        else -> throw CodegenException("unknown timestamp format: $tsFmt")
    }

    /**
     * Find and return the set of shapes that need `Encodable` conformance which includes top level input types with members in the http body
     * and their nested types.
     * Operation inputs and all nested types will conform to `Encodable`.
     *
     * @return The set of shapes that require a `Encodable` conformance and coding keys.
     */
    private fun resolveShapesNeedingEncodableConformance(ctx: ProtocolGenerator.GenerationContext): Set<Shape> {
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
     * Find and return the set of shapes that need `Decodable` conformance which includes top level output, error types with members returned in the http body
     * and their nested types.
     * Operation outputs, errors and all nested types will conform to `Decodable`.
     *
     * @return The set of shapes that require a `Decodable` conformance and coding keys.
     */
    private fun resolveShapesNeedingDecodableConformance(ctx: ProtocolGenerator.GenerationContext): Pair<Set<Shape>, Set<Shape>> {
        // all top level operation outputs, errors with an http body must conform to Decodable
        // any structure shape that shows up as a nested member (direct or indirect) needs to also conform to Decodable
        // get them all and return as one set to loop through

        val outputShapes = resolveOperationOutputShapes(ctx).filter { shapes -> shapes.members().any { it.isInHttpBody() } }.toMutableSet()
        val errorShapes = resolveOperationErrorShapes(ctx).filter { shapes -> shapes.members().any { it.isInHttpBody() } }.toMutableSet()

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

        val nested = walkNestedShapesRequiringSerde(ctx, topLevelOutputMembers.union(topLevelErrorMembers))
        return Pair(outputShapes.union(errorShapes), nested)
    }

    private fun resolveOperationInputShapes(ctx: ProtocolGenerator.GenerationContext): Set<Shape> {
        return getHttpBindingOperations(ctx).map { ctx.model.expectShape(it.input.get()) }.toSet()
    }

    private fun resolveOperationOutputShapes(ctx: ProtocolGenerator.GenerationContext): Set<Shape> {
        return getHttpBindingOperations(ctx).map { ctx.model.expectShape(it.output.get()) }.toSet()
    }

    private fun resolveOperationErrorShapes(ctx: ProtocolGenerator.GenerationContext): Set<Shape> {
        return getHttpBindingOperations(ctx)
            .flatMap { it.errors }
            .map { ctx.model.expectShape(it) }
            .toSet()
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
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
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
                renderSerializeExplicitPayload(ctx, httpPayload, writer)
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

    private fun renderSerializeExplicitPayload(ctx: ProtocolGenerator.GenerationContext, binding: HttpBinding, writer: SwiftWriter) {
        // explicit payload member as the sole payload
        val memberName = ctx.symbolProvider.toMemberName(binding.member)
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
            var memberName = ctx.symbolProvider.toMemberName(it.member)
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName
            val bindingIndex = HttpBindingIndex.of(ctx.model)

            writer.openBlock("if let $memberName = $memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    // Handle cases where member is a List or Set type
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
                                    HttpBinding.Location.QUERY,
                                    bindingIndex
                                )
                                writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($queryItemValue))")
                                writer.write("queryItems.append(queryItem)")
                            }
                        } else {
                            writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($queryItemValue))")
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
        val bindingIndex = HttpBindingIndex.of(ctx.model)
        writer.write("var headers = HttpHeaders()")
        // we only need the content type header in the request if there is an http body that is being sent
        if (hasHttpBody) {
            writer.write("headers.add(name: \"Content-Type\", value: \"$contentType\")")
        }
        headerBindings.forEach {
            val memberName = ctx.symbolProvider.toMemberName(it.member)
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
                                writer.write("headers.add(name: \"$paramName\", value: String($headerValue))")
                            }
                        } else {
                            writer.write("headers.add(name: \"$paramName\", value: String($headerValue))")
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
            val memberName = ctx.symbolProvider.toMemberName(it.member)
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
        val topDownIndex: TopDownIndex = TopDownIndex.of(ctx.model)
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
