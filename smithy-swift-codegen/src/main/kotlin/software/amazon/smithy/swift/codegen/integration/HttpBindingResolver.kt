/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.HttpTrait

/**
 * A generic subset of [HttpBinding] that is not specific to any protocol implementation.
 */
data class HttpBindingDescriptor(
    val member: MemberShape,
    val location: HttpBinding.Location,
    val locationName: String
) {
    constructor(httpBinding: HttpBinding) : this(httpBinding.member, httpBinding.location, httpBinding.locationName)
    val memberName: String = member.memberName
}

interface HttpBindingResolver {

    fun httpTrait(operationShape: OperationShape): HttpTrait

    fun responseBindings(shape: Shape): List<HttpBindingDescriptor>

    fun requestBindings(operationShape: OperationShape): List<HttpBindingDescriptor>

    fun determineRequestContentType(operationShape: OperationShape): String
}

class HttpTraitResolver(
    private val generationContext: ProtocolGenerator.GenerationContext,
    private val defaultContentType: String,
    private val bindingIndex: HttpBindingIndex = HttpBindingIndex.of(generationContext.model),
    private val topDownIndex: TopDownIndex = TopDownIndex.of(generationContext.model)
) : HttpBindingResolver {

    override fun httpTrait(operationShape: OperationShape): HttpTrait = operationShape.expectTrait(HttpTrait::class.java)

    override fun responseBindings(shape: Shape): List<HttpBindingDescriptor> {
        return when (shape) {
            is OperationShape,
            is StructureShape -> bindingIndex.getResponseBindings(shape.toShapeId()).values.map { HttpBindingDescriptor(it) }
            else -> error { "Unimplemented resolving bindings for ${shape.javaClass.canonicalName}" }
        }
    }

    override fun requestBindings(operationShape: OperationShape): List<HttpBindingDescriptor> {
        return bindingIndex.getRequestBindings(operationShape).values.map { HttpBindingDescriptor(it) }
    }

    override fun determineRequestContentType(operationShape: OperationShape): String = bindingIndex
        .determineRequestContentType(operationShape, defaultContentType)
        .orElse(defaultContentType)
}
