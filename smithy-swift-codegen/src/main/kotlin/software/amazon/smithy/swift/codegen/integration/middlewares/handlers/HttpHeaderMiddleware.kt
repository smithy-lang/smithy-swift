/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.formatHeaderOrQueryValue
import software.amazon.smithy.swift.codegen.integration.steps.OperationSerializeStep
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.needsDefaultValueCheck

class HttpHeaderMiddleware(
    private val writer: SwiftWriter,
    val ctx: ProtocolGenerator.GenerationContext,
    inputSymbol: Symbol,
    outputSymbol: Symbol,
    outputErrorSymbol: Symbol,
    private val headerBindings: List<HttpBindingDescriptor>,
    private val prefixHeaderBindings: List<HttpBindingDescriptor>,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : Middleware(writer, inputSymbol, OperationSerializeStep(inputSymbol, outputSymbol, outputErrorSymbol)) {

    private val bindingIndex = HttpBindingIndex.of(ctx.model)
    override val typeName = "${inputSymbol.name}HeadersMiddleware"
    companion object {
        fun renderHeaderMiddleware(
            ctx: ProtocolGenerator.GenerationContext,
            op: OperationShape,
            httpBindingResolver: HttpBindingResolver,
            defaultTimestampFormat: TimestampFormatTrait.Format
        ) {
            val requestBindings = httpBindingResolver.requestBindings(op)
            val headerBindings = requestBindings
                .filter { it.location == HttpBinding.Location.HEADER }
                .sortedBy { it.memberName }
            val prefixHeaderBindings = requestBindings
                .filter { it.location == HttpBinding.Location.PREFIX_HEADERS }

            val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
            val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
            val outputErrorSymbol = MiddlewareShapeUtils.outputErrorSymbol(op)
            val rootNamespace = MiddlewareShapeUtils.rootNamespace(ctx.settings)

            val headerMiddlewareSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${inputSymbol.name}+HeaderMiddleware.swift")
                .name(inputSymbol.name)
                .build()
            ctx.delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                val headerMiddleware = HttpHeaderMiddleware(writer, ctx, inputSymbol, outputSymbol, outputErrorSymbol, headerBindings, prefixHeaderBindings, defaultTimestampFormat)
                MiddlewareGenerator(writer, headerMiddleware).generate()
            }
        }
    }
    override fun generateMiddlewareClosure() {
        generateHeaders()
        generatePrefixHeaders()
    }

    override fun generateInit() {
        writer.write("public init() {}")
    }

    private fun generateHeaders() {

        headerBindings.forEach {
            var memberName = ctx.symbolProvider.toMemberName(it.member)
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName
            val isBoxed = ctx.symbolProvider.toSymbol(it.member).isBoxed()
            if (isBoxed) {
                writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                    if (memberTarget is CollectionShape) {
                        writer.openBlock("$memberName.forEach { headerValue in ", "}") {
                            renderHeader(memberTarget.member, "headerValue", paramName, true)
                        }
                    } else {
                        renderHeader(it.member, memberName, paramName)
                    }
                }
            } else {
                memberName = "input.operationInput.$memberName"
                renderHeader(it.member, memberName, paramName)
            }
        }
    }

    private fun renderHeader(member: MemberShape, memberName: String, paramName: String, inCollection: Boolean = false) {
        val (memberNameWithExtension, requiresDoCatch) = formatHeaderOrQueryValue(
            ctx,
            memberName,
            member,
            HttpBinding.Location.HEADER,
            bindingIndex,
            defaultTimestampFormat
        )

        if (requiresDoCatch) {
            renderDoCatch(memberNameWithExtension, paramName)
        } else {
            if (member.needsDefaultValueCheck(ctx.model, ctx.symbolProvider) && !inCollection) {
                writer.openBlock("if $memberName != ${member.defaultValue(ctx.symbolProvider)} {", "}") {
                    writer.write("input.builder.withHeader(name: \"$paramName\", value: \$N($memberNameWithExtension))", SwiftTypes.String)
                }
            } else {
                writer.write("input.builder.withHeader(name: \"$paramName\", value: \$N($memberNameWithExtension))", SwiftTypes.String)
            }
        }
    }

    private fun generatePrefixHeaders() {
        prefixHeaderBindings.forEach {
            val memberName = ctx.symbolProvider.toMemberName(it.member)
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName

            writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                val mapValueShape = memberTarget.asMapShape().get().value
                val mapValueShapeTarget = ctx.model.expectShape(mapValueShape.target)
                val mapValueShapeTargetSymbol = ctx.symbolProvider.toSymbol(mapValueShapeTarget)

                writer.openBlock("for (prefixHeaderMapKey, prefixHeaderMapValue) in $memberName { ", "}") {
                    if (mapValueShapeTarget is CollectionShape) {
                        writer.openBlock("prefixHeaderMapValue.forEach { headerValue in ", "}") {
                            if (mapValueShapeTargetSymbol.isBoxed()) {
                                writer.openBlock("if let unwrappedHeaderValue = headerValue {", "}") {
                                    renderHeader(mapValueShapeTarget.member, "unwrappedHeaderValue", "$paramName\\(prefixHeaderMapKey)", true)
                                }
                            } else {
                                renderHeader(mapValueShapeTarget.member, "headerValue", "$paramName\\(prefixHeaderMapKey)", true)
                            }
                        }
                    } else {
                        renderHeader(it.member, "prefixHeaderMapValue", "$paramName\\(prefixHeaderMapKey)", false)
                    }
                }
            }
        }
    }

    private fun renderDoCatch(headerValueWithExtension: String, headerName: String) {
        writer.openBlock("do {", "} catch let err {") {
            writer.write("let base64EncodedValue = $headerValueWithExtension")
            writer.write("input.builder.withHeader(name: \"$headerName\", value: \$N(base64EncodedValue))", SwiftTypes.String)
        }
        writer.indent()
        writer.write("return .failure(.client(\$N.serializationFailed(err.localizedDescription)))", ClientRuntimeTypes.Core.ClientError)
        writer.dedent()
        writer.write("}")
    }
}
