package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.isBoxed

class HttpHeaderMiddlewareGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeName: String,
    private val headerBindings: List<HttpBindingDescriptor>,
    private val prefixHeaderBindings: List<HttpBindingDescriptor>,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {

    private val bindingIndex = HttpBindingIndex.of(ctx.model)

    fun generate(writer: SwiftWriter) {
        MiddlewareGenerator(
            writer,
            "${shapeName}Headers",
            inputType = "SdkHttpRequestBuilder",
            outputType = "SdkHttpRequestBuilder"
        ) {
            generateHeaders(it)
            generatePrefixHeaders(it)
            it.write("return next.handle(context: context, input: input)")
        }.render()
    }

    private fun generateHeaders(writer: SwiftWriter) {
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
                        bindingIndex,
                        defaultTimestampFormat
                    )
                    writer.openBlock("$memberName.forEach { headerValue in ", "}") {
                        writer.write("input.withHeader(name: \"$paramName\", value: String($headerValue))")
                    }
                } else {
                    val memberNameWithExtension = formatHeaderOrQueryValue(
                        ctx,
                        memberName,
                        it.member,
                        HttpBinding.Location.HEADER,
                        bindingIndex,
                        defaultTimestampFormat
                    )
                    writer.write("input.withHeader(name: \"$paramName\", value: String($memberNameWithExtension))")
                }
            }
        }
    }

    private fun generatePrefixHeaders(writer: SwiftWriter) {
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
                            bindingIndex,
                            defaultTimestampFormat
                        )
                        writer.openBlock("prefixHeaderMapValue.forEach { headerValue in ", "}") {
                            if (mapValueShapeTargetSymbol.isBoxed()) {
                                writer.openBlock("if let unwrappedHeaderValue = headerValue {", "}") {
                                    headerValue = formatHeaderOrQueryValue(
                                        ctx,
                                        "unwrappedHeaderValue",
                                        mapValueShapeTarget.member,
                                        HttpBinding.Location.HEADER,
                                        bindingIndex,
                                        defaultTimestampFormat
                                    )
                                    writer.write("input.withHeader(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValue))")
                                }
                            } else {
                                writer.write("input.withHeader(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValue))")
                            }
                        }
                    } else {
                        var headerValue = formatHeaderOrQueryValue(
                            ctx,
                            "prefixHeaderMapValue",
                            it.member,
                            HttpBinding.Location.HEADER,
                            bindingIndex,
                            defaultTimestampFormat
                        )
                        writer.write("input.withHeader(name: \"$paramName\\(prefixHeaderMapKey)\", value: String($headerValue))")
                    }
                }
            }
        }
    }
}
