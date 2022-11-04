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
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
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
import software.amazon.smithy.swift.codegen.model.isRequired

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
                val rootNamespace = MiddlewareShapeUtils.rootNamespace(ctx.settings)
                val httpTrait = httpBindingResolver.httpTrait(op)
                val requestBindings = httpBindingResolver.requestBindings(op)
                val queryBindings =
                    requestBindings.filter { it.location == HttpBinding.Location.QUERY || it.location == HttpBinding.Location.QUERY_PARAMS }
                val queryLiterals = httpTrait.uri.queryLiterals
                val headerMiddlewareSymbol = Symbol.builder()
                    .definitionFile("./$rootNamespace/models/${inputSymbol.name}+QueryItemProvider.swift")
                    .name(inputSymbol.name)
                    .build()
                ctx.delegator.useShapeWriter(headerMiddlewareSymbol) { writer ->
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
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
        writer.openBlock("extension \$N: \$N {", "}", inputSymbol, ClientRuntimeTypes.Middleware.Providers.QueryItemProvider) {
            writer.openBlock("public func queryItems() throws -> [\$N] {", "}", ClientRuntimeTypes.Core.URLQueryItem) {
                writer.write("var items = [\$N]()", ClientRuntimeTypes.Core.URLQueryItem)
                generateQueryItems()
                writer.write("return items")
            }
        }
    }

    private fun generateQueryItems() {
        queryLiterals.forEach { (queryItemKey, queryItemValue) ->
            val queryValue = if (queryItemValue.isBlank()) "nil" else "\"${queryItemValue}\""
            writer.write("items.append(\$N(name: \$S, value: \$L))", ClientRuntimeTypes.Core.URLQueryItem, queryItemKey, queryValue)
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
        writer.openBlock("if let $memberName = $memberName {", "}") {
            val currentQueryItemsNames = "currentQueryItemNames"
            writer.write("let $currentQueryItemsNames = items.map({\$L.name})", "\$0")

            writer.openBlock("$memberName.forEach { key0, value0 in ", "}") {
                val valueTargetShape = ctx.model.expectShape(memberTarget.value.target)
                if (valueTargetShape is CollectionShape) {
                    writer.openBlock("if !$currentQueryItemsNames.contains(key0) {", "}") {
                        val suffix = if (memberTarget.hasTrait<SparseTrait>()) "?" else ""
                        writer.openBlock("value0$suffix.forEach { value1 in", "}") {
                            writer.write("let queryItem = \$N(name: key0.urlPercentEncoding(), value: value1.urlPercentEncoding())", ClientRuntimeTypes.Core.URLQueryItem)
                            writer.write("items.append(queryItem)")
                        }
                    }
                } else {
                    writer.openBlock("if !$currentQueryItemsNames.contains(key0) {", "}") {
                        writer.write("let queryItem = \$N(name: key0.urlPercentEncoding(), value: value0.urlPercentEncoding())", ClientRuntimeTypes.Core.URLQueryItem)
                        writer.write("items.append(queryItem)")
                    }
                }
            }
        }
    }

    fun renderHttpQuery(queryBinding: HttpBindingDescriptor, memberName: String, memberTarget: Shape, paramName: String, bindingIndex: HttpBindingIndex, isBoxed: Boolean) {
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
                } else {
                    renderQueryItem(queryBinding.member, bindingIndex, memberName, paramName)
                }
            }
            if (queryBinding.member.isRequired()) {
                writer.openBlock("else {", "}") {
                    writer.write(
                        "let message = \"Creating a URL Query Item failed. \$L is required but it is nil\"",
                        memberName
                    )
                    writer.write("throw SdkError<OperationStackError>.client(.queryItemCreationFailed(message))")
                }
            }
        } else {
            if (memberTarget is CollectionShape) {
                renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
            } else {
                renderQueryItem(queryBinding.member, bindingIndex, memberName, paramName)
            }
        }
    }

    private fun renderQueryItem(member: MemberShape, bindingIndex: HttpBindingIndex, originalMemberName: String, paramName: String) {
        var (memberName, requiresDoCatch) = formatHeaderOrQueryValue(
            ctx,
            originalMemberName,
            member,
            HttpBinding.Location.QUERY,
            bindingIndex,
            defaultTimestampFormat
        )
        if (requiresDoCatch) {
            renderDoCatch(memberName, paramName)
        } else {
            if (member.needsDefaultValueCheck(ctx.model, ctx.symbolProvider)) {
                writer.openBlock("if $memberName != ${member.defaultValue(ctx.symbolProvider)} {", "}") {
                    val queryItemName = "${ctx.symbolProvider.toMemberNames(member).second}QueryItem"
                    writer.write("let $queryItemName = \$N(name: \"$paramName\".urlPercentEncoding(), value: \$N($memberName).urlPercentEncoding())", ClientRuntimeTypes.Core.URLQueryItem, SwiftTypes.String)
                    writer.write("items.append($queryItemName)")
                }
            } else {
                val queryItemName = "${ctx.symbolProvider.toMemberNames(member).second}QueryItem"
                writer.write("let $queryItemName = \$N(name: \"$paramName\".urlPercentEncoding(), value: \$N($memberName).urlPercentEncoding())", ClientRuntimeTypes.Core.URLQueryItem, SwiftTypes.String)
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
                writer.write("let queryItem = \$N(name: \"$paramName\".urlPercentEncoding(), value: \$N($queryItemValue).urlPercentEncoding())", ClientRuntimeTypes.Core.URLQueryItem, SwiftTypes.String)
                writer.write("items.append(queryItem)")
            }
        }
    }

    private fun renderDoCatch(queryItemValueWithExtension: String, paramName: String) {
        writer.openBlock("do {", "} catch let err {") {
            writer.write("let base64EncodedValue = $queryItemValueWithExtension")
            writer.write("let queryItem = \$N(name: \"$paramName\".urlPercentEncoding(), value: \$N($queryItemValueWithExtension).urlPercentEncoding())", ClientRuntimeTypes.Core.URLQueryItem, SwiftTypes.String)
            writer.write("items.append(queryItem)")
        }
        writer.write("}")
    }
}
