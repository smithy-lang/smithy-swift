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
import software.amazon.smithy.swift.codegen.*
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.neighbor.RelationshipType
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.*
import software.amazon.smithy.utils.OptionalUtils
import software.amazon.smithy.utils.StringUtils

/**
 * Abstract implementation useful for all HTTP protocols
 */
abstract class HttpBindingProtocolGenerator : ProtocolGenerator {
    private val LOGGER = Logger.getLogger(javaClass.name)
    private var requestPayloadStructureBuilder: MutableList<String> = mutableListOf<String>()

    override fun generateSerializers(ctx: ProtocolGenerator.GenerationContext) {
        // render HttpSerialize for all operation inputs
        for (operation in getHttpBindingOperations(ctx)) {
            renderInputRequestConformanceToHttpSerialize(ctx, operation)
        }
    }

    /**
     * Generate request serializer (HttpSerialize) for an operation
     */
    private fun renderInputRequestConformanceToHttpSerialize(ctx: ProtocolGenerator.GenerationContext, op: OperationShape) {
        if (op.input.isEmpty()) {
            return
        }

        val inputShape = ctx.model.expectShape(op.input.get())
        val opIndex = ctx.model.getKnowledge(OperationIndex::class.java)
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(ctx.symbolProvider, opIndex, op)

        val bindingIndex = ctx.model.getKnowledge(HttpBindingIndex::class.java)
        val httpTrait = op.expectTrait(HttpTrait::class.java)
        val requestBindings = bindingIndex.getRequestBindings(op)
        val queryBindings = requestBindings.values.filter { it.location == HttpBinding.Location.QUERY }
        val pathBindings = requestBindings.values.filter { it.location == HttpBinding.Location.LABEL }
        val headerBindings = requestBindings.values
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val httpMethod: String = httpTrait.method.toLowerCase()
        val contentType = bindingIndex.determineRequestContentType(op, defaultContentType).orElse(defaultContentType)

        val prefixHeaderBindings = requestBindings.values
            .filter { it.location == HttpBinding.Location.PREFIX_HEADERS }

        ctx.delegator.useShapeWriter(inputShape) { writer ->
            writer.openBlock("extension $inputShapeName: HttpSerialize {", "}") {
                writer.openBlock("func encode(encoder: RequestEncoder) -> HttpRequest? {", "}") {
                    val path = resolveUriPath(httpTrait, pathBindings)
                    writer.write("let path = \"$path\"")
                    renderQueryItems(ctx, queryBindings, writer)
                    // TODO:: how do we get the host?
                    // TODO:: https://awslabs.github.io/smithy/1.0/spec/core/endpoint-traits.html
                    writer.write("let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: path, queryItems: queryItems)")
                    renderHeaders(ctx, headerBindings, prefixHeaderBindings, writer, contentType)
                    renderHttpBody(ctx, requestBindings, writer, "${inputShapeName}Payload")
                    writer.write("return HttpRequest(method: .$httpMethod, endpoint: endpoint, headers: headers, body: httpBody)")
                }
            }
        }
    }

    private fun renderQueryItems(ctx: ProtocolGenerator.GenerationContext,
                                 queryBindings: List<HttpBinding>,
                                 writer: SwiftWriter) {
        if (queryBindings.isNotEmpty()) {
            writer.write("var queryItems: [URLQueryItem]? = [URLQueryItem]()")
            writer.write("var queryItem: URLQueryItem")
        }
        queryBindings.forEach {
            var memberName = it.member.defaultName()
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName

            writer.openBlock("if let $memberName = $memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    // Handle cases where member is a List or Set type
                    writer.openBlock("$memberName.forEach { queryItemValue in ", "}") {
                        writer.write("queryItem = URLQueryItem(name: \"$paramName\", value: queryItemValue)")
                        writer.write("queryItems?.append(queryItem)")
                    }
                }
                else {
                    if (memberTarget.type == ShapeType.STRING &&
                        memberTarget.getTrait(EnumTrait::class.java).isPresent) {
                        memberName = "$memberName.rawValue"
                    }
                    writer.write("queryItem = URLQueryItem(name: \"$paramName\", value: $memberName)")
                    writer.write("queryItems?.append(queryItem)")
                }
            }
        }
    }

    // replace labels with any path bindings
    private fun resolveUriPath(httpTrait: HttpTrait, pathBindings: List<HttpBinding>): String {
        return httpTrait.uri.segments.joinToString(
            separator = "/",
            prefix = "/",
            postfix = "",
            transform = { segment ->
                if (segment.isLabel) {
                    // spec dictates member name and label name MUST be the same
                    val binding = pathBindings.find { binding ->
                        binding.memberName == segment.content
                    } ?: throw CodegenException("failed to find corresponding member for httpLabel `${segment.content}")
                    "\\(${binding.member.memberName})"
                } else {
                    // literal
                    segment.content
                }
            }
        )
    }

    private fun renderHeaders(ctx: ProtocolGenerator.GenerationContext,
                              headerBindings: List<HttpBinding>,
                              prefixHeaderBindings: List<HttpBinding>,
                              writer: SwiftWriter,
                              contentType: String) {
        if (headerBindings.isNotEmpty()) {
            writer.write("var headers = HttpHeaders()")
        }
        headerBindings.forEach {
            var memberName = it.member.defaultName()
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName
            writer.write("headers.add(name: \"Content-Type\", value: $contentType)")
            writer.openBlock("if let $memberName = $memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    // Handle cases where member is a List or Set type
                    writer.openBlock("$memberName.forEach { headerValue in ", "}") {
                        writer.write("headers.add(name: \"$paramName\", value: headerValue)")
                    }
                }
                else {
                    if (memberTarget.type == ShapeType.STRING &&
                        memberTarget.getTrait(EnumTrait::class.java).isPresent) {
                        memberName = "$memberName.rawValue"
                    }
                    writer.write("headers.add(name: \"$paramName\", value: $memberName)")
                }
            }
        }

        prefixHeaderBindings.forEach {
            var memberName = it.member.defaultName()
            val paramName = it.locationName

            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.openBlock("for (headerKey, headerValue) in $memberName { ", "}") {
                    writer.write("headers.add(name: \"$paramName\"headerKey, value: headerValue)")
                }
            }
        }
    }

    private fun renderHttpBody(ctx: ProtocolGenerator.GenerationContext,
                               requestBindings: Map<String, HttpBinding>,
                               writer: SwiftWriter,
                               payloadStructureName: String) {
        val httpPayload = requestBindings.values.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            renderHttpBodyFromPayload(ctx, httpPayload, writer)
        } else {
            // Unbound document members that should be serialized into the document format for the protocol.
            // The generated code is the same across protocols and the serialization provider instance
            // passed into the function is expected to handle the formatting required by the protocol
            val documentMemberBindings = requestBindings.values
                .filter { it.location == HttpBinding.Location.DOCUMENT }
                .sortedBy { it.memberName }

            renderHttpBodyFromDocumentMembers(ctx, documentMemberBindings, writer, payloadStructureName)
        }
    }

    private fun renderHttpBodyFromPayload(ctx: ProtocolGenerator.GenerationContext,
                                          httpPayloadBinding: HttpBinding,
                                          writer: SwiftWriter) {
        val memberName = httpPayloadBinding.member.defaultName()
        writer.write("var httpBody: HttpBody?")

        val isBinaryStream = ctx.model.getShape(httpPayloadBinding.member.target).get().hasTrait(StreamingTrait::class.java)
        if (isBinaryStream) {
            // TODO:: confirm this behavior
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write("httpBody = HttpBody.stream($memberName)")
            }
        } else {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write("httpBody = try! encodeBody($memberName, encoder: encoder)")
            }
        }
    }

    private fun renderHttpBodyFromDocumentMembers(ctx: ProtocolGenerator.GenerationContext,
                                                  documentMemberBindings: List<HttpBinding>,
                                                  writer: SwiftWriter,
                                                  payloadStructureName: String) {
        if (documentMemberBindings.isNotEmpty()) {
            val documentMemberShapes = documentMemberBindings.map { it.member }
            val documentMemberShapesSortedByName: List<MemberShape> = documentMemberShapes.sortedBy { ctx.symbolProvider.toMemberName(it) }

            if (documentMemberShapesSortedByName.isNotEmpty()) {
                writer.write("var httpBody: HttpBody?")
                val payloadStructureInitInputs: MutableList<String> = mutableListOf()

                // create and cache the request payload structure definition
                requestPayloadStructureBuilder.add("struct $payloadStructureName: Codable { ")
                for (member in documentMemberShapesSortedByName) {
                    val memberName = ctx.symbolProvider.toMemberName(member)
                    val memberSymbol = ctx.symbolProvider.toSymbol(member)
                    requestPayloadStructureBuilder.add("var $memberName: $memberSymbol")
                    payloadStructureInitInputs.add("$memberName:$memberName")
                }
                val payloadStructInstance = "$payloadStructureName(${payloadStructureInitInputs.joinToString(separator = ",")})"
                requestPayloadStructureBuilder.add("}")
                writer.write("httpBody = try! encodeBody($payloadStructInstance, encoder: encoder)")
            }
        }
    }


    override fun generateDeserializers(ctx: ProtocolGenerator.GenerationContext) {
        // render HttpDeserialize for all operation outputs, render normal serde for all shapes that appear as nested on any operation output
        // TODO("Not yet implemented")
    }

    override fun generateProtocolClient(ctx: ProtocolGenerator.GenerationContext) {
        val symbol = ctx.symbolProvider.toSymbol(ctx.service)
        ctx.delegator.useFileWriter("Default${symbol.name}.swift") { writer ->
            HttpProtocolClientGenerator(ctx.model, ctx.symbolProvider, writer, ctx.service).render()
        }
    }

    /**
     * The default content-type when a document is synthesized in the body.
     */
    protected abstract val defaultContentType: String

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
