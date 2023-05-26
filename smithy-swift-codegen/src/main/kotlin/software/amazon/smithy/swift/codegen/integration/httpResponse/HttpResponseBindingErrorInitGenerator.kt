/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitPayload
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitPayloadFactory
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitQueryParams
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitResponseCode

interface HttpResponseBindingErrorInitGeneratorFactory {
    fun construct(
        ctx: ProtocolGenerator.GenerationContext,
        structureShape: StructureShape,
        httpBindingResolver: HttpBindingResolver,
        defaultTimestampFormat: TimestampFormatTrait.Format
    ): HttpResponseBindingRenderable
}

class HttpResponseBindingErrorInitGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val shape: StructureShape,
    val httpBindingResolver: HttpBindingResolver,
    val defaultTimestampFormat: TimestampFormatTrait.Format,
    val httpResponseTraitPayloadFactory: HttpResponseTraitPayloadFactory? = null
) : HttpResponseBindingRenderable {

    object HttpResponseBindingErrorInit : SectionId
    object HttpResponseBindingErrorInitMemberAssignment : SectionId

    override fun render() {
        val responseBindings = httpBindingResolver.responseBindings(shape)
        val headerBindings = responseBindings
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val errorShapeName = ctx.symbolProvider.toSymbol(shape).name

        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$errorShapeName+Init.swift")
            .name(errorShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.openBlock("extension \$L {", "}", errorShapeName) {
                writer.declareSection(HttpResponseBindingErrorInit) {
                    writer.write(
                        "public init(httpResponse: \$N, decoder: \$D, message: \$D, requestID: \$D) async throws {",
                        ClientRuntimeTypes.Http.HttpResponse,
                        ClientRuntimeTypes.Serde.ResponseDecoder,
                        SwiftTypes.String,
                        SwiftTypes.String
                    )
                }

                writer.indent()
                HttpResponseHeaders(ctx, headerBindings, defaultTimestampFormat, writer).render()
                HttpResponsePrefixHeaders(ctx, responseBindings, writer).render()
                httpResponseTraitPayload(ctx, responseBindings, errorShapeName, writer)
                HttpResponseTraitQueryParams(ctx, responseBindings, writer).render()
                HttpResponseTraitResponseCode(ctx, responseBindings, writer).render()
                writer.write("self._headers = httpResponse.headers")
                writer.write("self._statusCode = httpResponse.statusCode")
                writer.write("self._requestID = requestID")
                writer.write("self._message = message")
                writer.declareSection(HttpResponseBindingErrorInitMemberAssignment)
                writer.dedent()
                writer.write("}")
            }
            writer.write("")
        }
    }

    fun httpResponseTraitPayload(ctx: ProtocolGenerator.GenerationContext, responseBindings: List<HttpBindingDescriptor>, errorShapeName: String, writer: SwiftWriter) {
        val responseTraitPayload = httpResponseTraitPayloadFactory?.let {
            it.construct(ctx, responseBindings, errorShapeName, writer)
        } ?: run {
            HttpResponseTraitPayload(ctx, responseBindings, errorShapeName, writer)
        }
        responseTraitPayload.render()
    }
}
