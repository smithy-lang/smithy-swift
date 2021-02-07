package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.isBoxed

class HttpHeaderMiddleware(private val writer: SwiftWriter,
                           private val ctx: ProtocolGenerator.GenerationContext,
                           private val symbol: Symbol,
                           private val headerBindings: List<HttpBindingDescriptor>,
                           private val prefixHeaderBindings: List<HttpBindingDescriptor>,
                           private val defaultTimestampFormat: TimestampFormatTrait.Format) : Middleware(writer, symbol) {

    private val bindingIndex = HttpBindingIndex.of(ctx.model)

    override val inputType = Symbol
        .builder()
        .name("SdkHttpRequestBuilder")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()

    override val outputType = Symbol
        .builder()
        .name("SdkHttpRequestBuilder")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()

    override val properties = mutableMapOf(symbol.name.decapitalize() to symbol)

    override fun generateMiddlewareClosure() {
        generateHeaders()
        generatePrefixHeaders()
        super.generateMiddlewareClosure()
    }

    private fun generateHeaders() {
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

    private fun generatePrefixHeaders() {
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