package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MemberShape
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

        queryBindings.forEach {
            var memberName = ctx.symbolProvider.toMemberName(it.member)
            val memberTarget = ctx.model.expectShape(it.member.target)
            val paramName = it.locationName
            val bindingIndex = HttpBindingIndex.of(ctx.model)
            val isBoxed = ctx.symbolProvider.toSymbol(it.member).isBoxed()

            if (isBoxed) {
                writer.openBlock("if let $memberName = input.operationInput.$memberName {", "}") {
                    if (memberTarget is CollectionShape) {
                        renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
                    } else {
                        renderQueryItem(it.member, bindingIndex, memberName, paramName)
                    }
                }
            } else {
                if (memberTarget is CollectionShape) {
                    memberName = "input.operationInput.$memberName"
                    renderListOrSet(memberTarget, bindingIndex, memberName, paramName)
                } else {
                    renderQueryItem(it.member, bindingIndex, memberName, paramName)
                }
            }
        }
    }

    private fun renderQueryItem(member: MemberShape, bindingIndex: HttpBindingIndex, memberName: String, paramName: String) {
        var (memberName, requiresDoCatch) = formatHeaderOrQueryValue(
                ctx,
                memberName,
                member,
                HttpBinding.Location.QUERY,
                bindingIndex,
                defaultTimestampFormat
        )
        if (requiresDoCatch) {
            renderDoCatch(memberName, paramName)
        } else {
            writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($memberName))")
            writer.write("input.builder.withQueryItem(queryItem)")
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
                writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($queryItemValue))")
                writer.write("input.builder.withQueryItem(queryItem)")
            }
        }
    }

    private fun renderDoCatch(queryItemValueWithExtension: String, queryItemName: String) {
        writer.openBlock("do {", "} catch let err {") {
            writer.write("let base64EncodedValue = $queryItemValueWithExtension")
            writer.write("let queryItem = URLQueryItem(name: \"$queryItemName\", value: String($queryItemValueWithExtension))")
            writer.write("input.builder.withQueryItem(queryItem)")
        }
        writer.indent()
        writer.write("return .failure(err)")
        writer.dedent()
        writer.write("}")
    }
}
