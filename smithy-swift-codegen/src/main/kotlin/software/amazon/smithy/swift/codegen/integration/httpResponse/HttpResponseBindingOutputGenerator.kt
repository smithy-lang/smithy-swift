/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitPayload
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitQueryParams
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitResponseCode
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils

class HttpResponseBindingOutputGenerator(): HttpResponseBindingOutputGeneratable {

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape,
        httpBindingResolver: HttpBindingResolver,
        defaultTimestampFormat: TimestampFormatTrait.Format
    ) {
        if (op.output.isEmpty) {
            return
        }
        val outputShape = ctx.model.expectShape(op.outputShape)
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op).name
        var responseBindings = httpBindingResolver.responseBindings(op)
        val headerBindings = responseBindings
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$outputShapeName+HttpResponseBinding.swift")
            .name(outputShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.openBlock("extension $outputShapeName: \$N {", "}", ClientRuntimeTypes.Http.HttpResponseBinding) {
                writer.openBlock(
                    "public init(httpResponse: \$N, decoder: \$D) async throws {",
                    "}",
                    ClientRuntimeTypes.Http.HttpResponse,
                    ClientRuntimeTypes.Serde.ResponseDecoder
                ) {
                    HttpResponseHeaders(ctx, false, headerBindings, defaultTimestampFormat, writer).render()
                    HttpResponsePrefixHeaders(ctx, responseBindings, writer).render()
                    HttpResponseTraitPayload(ctx, responseBindings, outputShape, writer).render()
                    HttpResponseTraitQueryParams(ctx, responseBindings, writer).render()
                    HttpResponseTraitResponseCode(ctx, responseBindings, writer).render()
                }
            }
            writer.write("")
        }
    }
}
