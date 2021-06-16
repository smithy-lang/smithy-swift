package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.steps.OperationSerializeStep
import software.amazon.smithy.swift.codegen.isBoxed

class HttpQueryItemMiddleware(
    private val ctx: ProtocolGenerator.GenerationContext,
    inputSymbol: Symbol,
    outputSymbol: Symbol,
    outputErrorSymbol: Symbol,
    private val queryLiterals: Map<String, String>,
    private val queryBindings: List<HttpBindingDescriptor>,
    private val defaultTimestampFormat: TimestampFormatTrait.Format,
    private val writer: SwiftWriter
) : Middleware(writer, inputSymbol, OperationSerializeStep(inputSymbol, outputSymbol, outputErrorSymbol)) {

    override val typeName = "${inputSymbol.name}QueryItemMiddleware"

    override fun generateMiddlewareClosure() {
        generateQueryItems()
    }

    override fun generateInit() {
        writer.write("public init() {}")
    }

    private fun generateQueryItems() {

        queryLiterals.forEach { (queryItemKey, queryItemValue) ->
            val queryValue = if (queryItemValue.isBlank()) "nil" else "\"${queryItemValue}\""
            writer.write("input.builder.withQueryItem(URLQueryItem(name: \$S, value: \$L))", queryItemKey, queryValue)
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
        writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
            val currentQueryItemsNames = "currentQueryItemNames"
            writer.write("let $currentQueryItemsNames = input.builder.currentQueryItems.map({\$L.name})", "\$0")

            writer.openBlock("$memberName.forEach { key0, value0 in ", "}") {
                val valueTargetShape = ctx.model.expectShape(memberTarget.value.target)
                if (valueTargetShape is CollectionShape) {
                    writer.openBlock("if !$currentQueryItemsNames.contains(key0) {", "}") {
                        writer.openBlock("value0?.forEach { value1 in", "}") {
                            writer.write("let queryItem = URLQueryItem(name: key0.urlPercentEncoding(), value: value1.urlPercentEncoding())")
                            writer.write("input.builder.withQueryItem(queryItem)")
                        }
                    }
                } else {
                    writer.openBlock("if !$currentQueryItemsNames.contains(key0) {", "}") {
                        writer.write("let queryItem = URLQueryItem(name: key0.urlPercentEncoding(), value: value0.urlPercentEncoding())")
                        writer.write("input.builder.withQueryItem(queryItem)")
                    }
                }
            }
        }
    }

    fun renderHttpQuery(queryBinding: HttpBindingDescriptor, memberName: String, memberTarget: Shape, paramName: String, bindingIndex: HttpBindingIndex, isBoxed: Boolean) {
        if (isBoxed) {
            writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                if (memberTarget is CollectionShape) {
                    renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
                } else {
                    renderQueryItem(queryBinding.member, bindingIndex, memberName, paramName)
                }
            }
        } else {
            val updatedMemberName = "input.operationInput.$memberName"
            if (memberTarget is CollectionShape) {
                renderListOrSet(memberTarget, bindingIndex, updatedMemberName, paramName)
            } else {
                renderQueryItem(queryBinding.member, bindingIndex, updatedMemberName, paramName)
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
            val queryItemName = "${ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")}QueryItem"
            writer.write("let $queryItemName = URLQueryItem(name: \"$paramName\".urlPercentEncoding(), value: String($memberName).urlPercentEncoding())")
            writer.write("input.builder.withQueryItem($queryItemName)")
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
                writer.write("let queryItem = URLQueryItem(name: \"$paramName\".urlPercentEncoding(), value: String($queryItemValue).urlPercentEncoding())")
                writer.write("input.builder.withQueryItem(queryItem)")
            }
        }
    }

    private fun renderDoCatch(queryItemValueWithExtension: String, paramName: String) {
        writer.openBlock("do {", "} catch let err {") {
            writer.write("let base64EncodedValue = $queryItemValueWithExtension")
            writer.write("let queryItem = URLQueryItem(name: \"$paramName\".urlPercentEncoding(), value: String($queryItemValueWithExtension).urlPercentEncoding())")
            writer.write("input.builder.withQueryItem(queryItem)")
        }
        writer.indent()
        writer.write("return .failure(.client(ClientError.serializationFailed(err.localizedDescription)))")
        writer.dedent()
        writer.write("}")
    }
}
