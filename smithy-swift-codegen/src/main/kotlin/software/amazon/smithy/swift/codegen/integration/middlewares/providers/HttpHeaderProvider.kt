/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares.providers

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.formatHeaderOrQueryValue
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.needsDefaultValueCheck
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

class HttpHeaderProvider(
    private val writer: SwiftWriter,
    val ctx: ProtocolGenerator.GenerationContext,
    private val inputSymbol: Symbol,
    private val headerBindings: List<HttpBindingDescriptor>,
    private val prefixHeaderBindings: List<HttpBindingDescriptor>,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {

    private val bindingIndex = HttpBindingIndex.of(ctx.model)
    companion object {
        fun renderHeaderMiddleware(
            ctx: ProtocolGenerator.GenerationContext,
            op: OperationShape,
            httpBindingResolver: HttpBindingResolver,
            defaultTimestampFormat: TimestampFormatTrait.Format
        ) {
            if (MiddlewareShapeUtils.hasHttpHeaders(ctx.model, op)) {
                val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
                val requestBindings = httpBindingResolver.requestBindings(op)
                val headerBindings = requestBindings
                    .filter { it.location == HttpBinding.Location.HEADER }
                    .sortedBy { it.memberName }
                val prefixHeaderBindings = requestBindings
                    .filter { it.location == HttpBinding.Location.PREFIX_HEADERS }
                val filename = ModelFileUtils.filename(ctx.settings, "${inputSymbol.name}+HeaderProvider")
                val headerMiddlewareSymbol = Symbol.builder()
                    .definitionFile(filename)
                    .name(inputSymbol.name)
                    .build()
                ctx.delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
                    HttpHeaderProvider(writer, ctx, inputSymbol, headerBindings, prefixHeaderBindings, defaultTimestampFormat).renderProvider(writer)
                }
            }
        }
    }

    fun renderProvider(writer: SwiftWriter) {
        writer.openBlock("extension \$N {", "}", inputSymbol) {
            writer.write("")
            writer.openBlock(
                "static func headerProvider(_ value: \$N) -> \$N {",
                "}",
                inputSymbol,
                SmithyHTTPAPITypes.Headers,
            ) {
                writer.write("var items = \$N()", SmithyHTTPAPITypes.Headers)
                generateHeaders()
                generatePrefixHeaders()
                writer.write("return items")
            }
        }
    }

    private fun generateHeaders() {
        headerBindings.forEach {
            var memberName = ctx.symbolProvider.toMemberName(it.member)
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName
            val isBoxed = ctx.symbolProvider.toSymbol(it.member).isBoxed()
            if (isBoxed) {
                writer.openBlock("if let $memberName = value.$memberName {", "}") {
                    if (memberTarget is CollectionShape) {
                        writer.openBlock("$memberName.forEach { headerValue in ", "}") {
                            renderHeader(memberTarget.member, "headerValue", paramName, true)
                        }
                    } else {
                        renderHeader(it.member, memberName, paramName)
                    }
                }
            } else {
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
            defaultTimestampFormat,
        )

        if (requiresDoCatch) {
            renderDoCatch(memberNameWithExtension, paramName)
        } else {
            if (member.needsDefaultValueCheck(ctx.model, ctx.symbolProvider) && !inCollection) {
                writer.openBlock("if $memberName != ${member.defaultValue(ctx.symbolProvider)} {", "}") {
                    writer.write(
                        "items.add(\$N(name: \$S, value: \$N(\$L)))",
                        SmithyHTTPAPITypes.Header,
                        paramName,
                        SwiftTypes.String,
                        memberNameWithExtension,
                    )
                }
            } else if (inCollection && ctx.model.expectShape(member.target) !is TimestampShape) {
                writer.write(
                    "items.add(\$N(name: \$S, value: quoteHeaderValue(\$N(\$L))))",
                    SmithyHTTPAPITypes.Header,
                    paramName,
                    SwiftTypes.String,
                    memberNameWithExtension,
                )
            } else {
                writer.write(
                    "items.add(\$N(name: \$S, value: \$N(\$L)))",
                    SmithyHTTPAPITypes.Header,
                    paramName,
                    SwiftTypes.String,
                    memberNameWithExtension,
                )
            }
        }
    }

    private fun generatePrefixHeaders() {
        prefixHeaderBindings.forEach {
            val memberName = ctx.symbolProvider.toMemberName(it.member)
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName

            writer.openBlock("if let $memberName = value.$memberName {", "}") {
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
        writer.openBlock("do {", "} catch {") {
            writer.write("let base64EncodedValue = \$L", headerValueWithExtension)
            writer.write(
                "items.add(\$N(name: \$S, value: \$N(base64EncodedValue)))",
                SmithyHTTPAPITypes.Header,
                headerName,
                SwiftTypes.String,
            )
        }
        writer.write("}")
    }
}
