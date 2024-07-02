/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares.providers

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.formatHeaderOrQueryValue
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.needsDefaultValueCheck
import software.amazon.smithy.swift.codegen.model.toMemberNames
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

class HttpQueryItemProvider(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val inputSymbol: Symbol,
    private val queryLiterals: Map<String, String>,
    private val queryBindings: List<HttpBindingDescriptor>,
    private val defaultTimestampFormat: TimestampFormatTrait.Format,
    private val writer: SwiftWriter
) {
    companion object {
        fun renderQueryMiddleware(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, httpBindingResolver: HttpBindingResolver, defaultTimestampFormat: TimestampFormatTrait.Format) {
            if (MiddlewareShapeUtils.hasQueryItems(ctx.model, op)) {
                val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
                val httpTrait = httpBindingResolver.httpTrait(op)
                val requestBindings = httpBindingResolver.requestBindings(op)
                val queryBindings =
                    requestBindings.filter { it.location == HttpBinding.Location.QUERY || it.location == HttpBinding.Location.QUERY_PARAMS }
                val queryLiterals = httpTrait.uri.queryLiterals
                val filename = ModelFileUtils.filename(ctx.settings, "${inputSymbol.name}+QueryItemProvider")
                val headerMiddlewareSymbol = Symbol.builder()
                    .definitionFile(filename)
                    .name(inputSymbol.name)
                    .build()
                ctx.delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
                    val queryItemMiddleware = HttpQueryItemProvider(
                        ctx,
                        inputSymbol,
                        queryLiterals,
                        queryBindings,
                        defaultTimestampFormat,
                        writer
                    )
                    queryItemMiddleware.renderProvider(writer)
                }
            }
        }
    }

    fun renderProvider(writer: SwiftWriter) {
        writer.openBlock("extension \$N {", "}", inputSymbol) {
            writer.write("")
            writer.openBlock(
                "static func queryItemProvider(_ value: \$N) throws -> [\$N] {",
                "}",
                inputSymbol,
                SmithyTypes.URIQueryItem,
            ) {
                if (queryLiterals.isEmpty() && queryBindings.isEmpty()) {
                    writer.write("return []")
                } else {
                    writer.write("var items = [\$N]()", SmithyTypes.URIQueryItem)
                    generateQueryItems()
                    writer.write("return items")
                }
            }
        }
    }

    private fun generateQueryItems() {
        queryLiterals.forEach { (queryItemKey, queryItemValue) ->
            val queryValue = if (queryItemValue.isBlank()) "nil" else "\"${queryItemValue}\""
            writer.write("items.append(\$N(name: \$S, value: \$L))", SmithyTypes.URIQueryItem, queryItemKey, queryValue)
        }

        var httpQueryParamBinding: HttpBindingDescriptor? = null
        queryBindings.forEach {
            var memberName = ctx.symbolProvider.toMemberName(it.member)
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName
            val bindingIndex = HttpBindingIndex.of(ctx.model)
            val isBoxed = ctx.symbolProvider.toSymbol(it.member).isBoxed()

            if (it.location == HttpBinding.Location.QUERY_PARAMS && memberTarget is MapShape) {
                httpQueryParamBinding = it
            } else if (it.location == HttpBinding.Location.QUERY) {
                renderHttpQuery(it, memberName, memberTarget, paramName, bindingIndex, isBoxed)
            }
        }
        httpQueryParamBinding?.let {
            val memberTarget = ctx.model.expectShape(it.member.target)
            var memberName = ctx.symbolProvider.toMemberName(it.member)
            if (memberTarget is MapShape) {
                renderHttpQueryParamMap(memberTarget, memberName)
            }
        }
    }

    private fun renderHttpQueryParamMap(memberTarget: MapShape, memberName: String) {
        writer.openBlock("if let $memberName = value.$memberName {", "}") {
            val currentQueryItemsNames = "currentQueryItemNames"
            writer.write("let $currentQueryItemsNames = items.map({\$L.name})", "\$0")

            writer.openBlock("$memberName.forEach { key0, value0 in ", "}") {
                val valueTargetShape = ctx.model.expectShape(memberTarget.value.target)
                if (valueTargetShape is CollectionShape) {
                    writer.openBlock("if !$currentQueryItemsNames.contains(key0) {", "}") {
                        val suffix = if (memberTarget.hasTrait<SparseTrait>()) "?" else ""
                        writer.openBlock("value0$suffix.forEach { value1 in", "}") {
                            writer.write("let queryItem = \$N(name: key0.urlPercentEncoding(), value: value1.urlPercentEncoding())", SmithyTypes.URIQueryItem)
                            writer.write("items.append(queryItem)")
                        }
                    }
                } else {
                    writer.openBlock("if !$currentQueryItemsNames.contains(key0) {", "}") {
                        writer.write("let queryItem = \$N(name: key0.urlPercentEncoding(), value: value0.urlPercentEncoding())", SmithyTypes.URIQueryItem)
                        writer.write("items.append(queryItem)")
                    }
                }
            }
        }
    }

    fun renderHttpQuery(queryBinding: HttpBindingDescriptor, memberName: String, memberTarget: Shape, paramName: String, bindingIndex: HttpBindingIndex, isBoxed: Boolean) {
        if (isBoxed) {
            if (queryBinding.member.isRequired()) {
                writer.openBlock("guard let \$L = value.\$L else {", "}", memberName, memberName) {
                    writer.write(
                        "let message = \"Creating a URL Query Item failed. \$L is required and must not be nil.\"",
                        memberName
                    )
                    writer.write("throw \$N.unknownError(message)", SmithyTypes.ClientError)
                }
                if (memberTarget is CollectionShape) {
                    renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
                } else {
                    renderQueryItem(queryBinding.member, bindingIndex, memberName, paramName, true)
                }
            } else {
                writer.openBlock("if let $memberName = value.$memberName {", "}") {
                    if (memberTarget is CollectionShape) {
                        renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
                    } else {
                        renderQueryItem(queryBinding.member, bindingIndex, memberName, paramName, true)
                    }
                }
            }
        } else {
            if (memberTarget is CollectionShape) {
                renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
            } else {
                renderQueryItem(queryBinding.member, bindingIndex, memberName, paramName, false)
            }
        }
    }

    private fun renderQueryItem(member: MemberShape, bindingIndex: HttpBindingIndex, originalMemberName: String, paramName: String, unwrapped: Boolean) {
        var (memberName, requiresDoCatch) = formatHeaderOrQueryValue(
            ctx,
            writer,
            originalMemberName,
            member,
            HttpBinding.Location.QUERY,
            bindingIndex,
            defaultTimestampFormat
        )
        if (requiresDoCatch) {
            renderDoCatch(memberName, paramName)
        } else {
            val prefix = "".takeIf { unwrapped } ?: "value."
            if (member.needsDefaultValueCheck(ctx.model, ctx.symbolProvider)) {
                writer.openBlock(
                    "if value.\$L != \$L {",
                    "}",
                    memberName,
                    member.defaultValue(ctx.symbolProvider),
                ) {
                    val queryItemName = "${ctx.symbolProvider.toMemberNames(member).second}QueryItem"
                    writer.write(
                        "let \$L = \$N(name: \$S.urlPercentEncoding(), value: \$N(\$L\$L).urlPercentEncoding())",
                        queryItemName,
                        SmithyTypes.URIQueryItem,
                        paramName,
                        SwiftTypes.String,
                        prefix,
                        memberName,
                    )
                    writer.write("items.append($queryItemName)")
                }
            } else {
                val queryItemName = "${ctx.symbolProvider.toMemberNames(member).second}QueryItem"
                writer.write(
                    "let \$L = \$N(name: \$S.urlPercentEncoding(), value: \$N(\$L\$L).urlPercentEncoding())",
                    queryItemName,
                    SmithyTypes.URIQueryItem,
                    paramName,
                    SwiftTypes.String,
                    prefix,
                    memberName,
                )
                writer.write("items.append($queryItemName)")
            }
        }
    }

    private fun renderListOrSet(
        memberTarget: CollectionShape,
        bindingIndex: HttpBindingIndex,
        memberName: String,
        paramName: String
    ) {
        var (queryItemValue, requiresDoCatch) = formatHeaderOrQueryValue(
            ctx,
            writer,
            "queryItemValue",
            memberTarget.member,
            HttpBinding.Location.QUERY,
            bindingIndex,
            defaultTimestampFormat
        )

        writer.openBlock("$memberName.forEach { queryItemValue in ", "}") {
            if (requiresDoCatch) {
                renderDoCatch(queryItemValue, paramName)
            } else {
                writer.write("let queryItem = \$N(name: \"$paramName\".urlPercentEncoding(), value: \$N($queryItemValue).urlPercentEncoding())", SmithyTypes.URIQueryItem, SwiftTypes.String)
                writer.write("items.append(queryItem)")
            }
        }
    }

    private fun renderDoCatch(queryItemValueWithExtension: String, paramName: String) {
        writer.openBlock("do {", "} catch let err {") {
            writer.write("let base64EncodedValue = $queryItemValueWithExtension")
            writer.write("let queryItem = \$N(name: \"$paramName\".urlPercentEncoding(), value: \$N($queryItemValueWithExtension).urlPercentEncoding())", SmithyTypes.URIQueryItem, SwiftTypes.String)
            writer.write("items.append(queryItem)")
        }
        writer.write("}")
    }
}
