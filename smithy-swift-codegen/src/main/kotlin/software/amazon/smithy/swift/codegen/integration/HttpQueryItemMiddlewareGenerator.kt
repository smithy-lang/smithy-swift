package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter

class HttpQueryItemMiddlewareGenerator(private val ctx: ProtocolGenerator.GenerationContext,
                                       private val shapeName: String,
                                       private val queryLiterals: Map<String, String>,
                                       private val queryBindings: List<HttpBindingDescriptor>,
                                       private val defaultTimestampFormat: TimestampFormatTrait.Format,
                                       private val writer: SwiftWriter) {
    fun generate() {
        MiddlewareGenerator(
            writer,
            "${shapeName}QueryItem",
            inputType = "SdkHttpRequestBuilder",
            outputType = "SdkHttpRequestBuilder"
        ) {
            generateQueryItems(it)
            it.write("return next.handle(context: context, input: input)")
        }.render()
    }

    private fun generateQueryItems(writer: SwiftWriter) {

        queryLiterals.forEach { (queryItemKey, queryItemValue) ->
            val queryValue = if (queryItemValue.isBlank()) "nil" else "\"${queryItemValue}\""
            writer.write("input.withQueryItem(URLQueryItem(name: \$S, value: \$L))", queryItemKey, queryValue)
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
                        bindingIndex,
                        defaultTimestampFormat
                    )
                    val collectionMemberTargetShape = ctx.model.expectShape(memberTarget.member.target)
                    val collectionMemberTargetSymbol = ctx.symbolProvider.toSymbol(collectionMemberTargetShape)
                    writer.openBlock("$memberName.forEach { queryItemValue in ", "}") {
                        writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($queryItemValue))")
                        writer.write("input.withQueryItem(queryItem)")
                    }
                } else {
                    memberName = formatHeaderOrQueryValue(
                        ctx,
                        memberName,
                        it.member,
                        HttpBinding.Location.QUERY,
                        bindingIndex,
                        defaultTimestampFormat
                    )
                    writer.write("let queryItem = URLQueryItem(name: \"$paramName\", value: String($memberName))")
                    writer.write("input.withQueryItem(queryItem)")
                }
            }
        }
    }
}