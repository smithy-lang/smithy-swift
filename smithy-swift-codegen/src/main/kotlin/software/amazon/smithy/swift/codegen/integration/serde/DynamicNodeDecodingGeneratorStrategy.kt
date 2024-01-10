/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlAttributeTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.integration.serde.xml.DynamicNodeDecodingXMLGenerator

class DynamicNodeDecodingGeneratorStrategy(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shape: Shape,
    private val isForBodyStruct: Boolean
) {
    fun renderIfNeeded() {
        if (shouldRenderDynamicNodeDecodingProtocol(ctx, shape)) {
            DynamicNodeDecodingXMLGenerator(ctx, shape, isForBodyStruct).render()
        }
    }

    private fun shouldRenderDynamicNodeDecodingProtocol(ctx: ProtocolGenerator.GenerationContext, shape: Shape): Boolean {
        return isRestXmlProtocolAndHasXmlAttributesInMembers(ctx, shape)
    }
}

fun isRestXmlProtocolAndHasXmlAttributesInMembers(ctx: ProtocolGenerator.GenerationContext, shape: Shape): Boolean {
    val isRestXML = ctx.protocol == RestXmlTrait.ID
    if (isRestXML) {
        return shape.members()
            .filter { it.isInHttpBody() }
            .filter { it.hasTrait(XmlAttributeTrait::class.java) }
            .isNotEmpty()
    }
    return false
}
