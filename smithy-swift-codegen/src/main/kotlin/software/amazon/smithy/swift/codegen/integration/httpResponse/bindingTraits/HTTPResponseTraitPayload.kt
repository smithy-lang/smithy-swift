/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HTTPResponseBindingRenderable

class HTTPResponseTraitPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val outputShape: Shape,
    val writer: SwiftWriter,
    val customizations: HTTPProtocolCustomizable,
    val httpResponseTraitWithoutPayloadFactory: HTTPResponseTraitWithoutHTTPPayloadFactory? = null,
) : HTTPResponseBindingRenderable {
    override fun render() {
        val httpPayload = responseBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            HTTPResponseTraitWithHTTPPayload(ctx, httpPayload, writer, outputShape, customizations).render()
        } else {
            val httpResponseTraitWithoutPayload = httpResponseTraitWithoutPayloadFactory?.let {
                it.construct(ctx, responseBindings, outputShape, writer)
            } ?: run {
                HTTPResponseTraitWithoutHTTPPayload(ctx, responseBindings, outputShape, writer, customizations)
            }
            httpResponseTraitWithoutPayload.render()
        }
    }
}
