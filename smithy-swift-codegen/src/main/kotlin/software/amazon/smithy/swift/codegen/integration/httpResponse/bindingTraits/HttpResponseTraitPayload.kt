/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingRenderable

interface HttpResponseTraitPayloadFactory {
    fun construct(
        ctx: ProtocolGenerator.GenerationContext,
        responseBindings: List<HttpBindingDescriptor>,
        errorShape: Shape,
        writer: SwiftWriter
    ): HttpResponseBindingRenderable
}

class HttpResponseTraitPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val outputShape: Shape,
    val writer: SwiftWriter,
    val httpResponseTraitWithoutPayloadFactory: HttpResponseTraitWithoutHttpPayloadFactory? = null
) : HttpResponseBindingRenderable {
    override fun render() {
        val httpPayload = responseBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            HttpResponseTraitWithHttpPayload(ctx, httpPayload, writer).render()
        } else {
            val httpResponseTraitWithoutPayload = httpResponseTraitWithoutPayloadFactory?.let {
                it.construct(ctx, responseBindings, outputShape, writer)
            } ?: run {
                XMLHttpResponseTraitWithoutHttpPayload(ctx, responseBindings, outputShape, writer)
            }
            httpResponseTraitWithoutPayload.render()
        }
    }
}
