
/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.selector.Selector
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.NumberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.DeprecatedTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.model.traits.RequiredTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.model.traits.Trait
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.utils.StringUtils

@Suppress("EXTENSION_SHADOWED_BY_MEMBER")
inline fun <reified T : Shape> Model.shapes(): List<T> = shapes(T::class.java).toList()

@Suppress("EXTENSION_SHADOWED_BY_MEMBER")
inline fun <reified T : Shape> Model.expectShape(shapeId: ShapeId): T =
    expectShape(shapeId, T::class.java)

inline fun <reified T : Shape> Model.expectShape(shapeId: String): T =
    this.expectShape(ShapeId.from(shapeId), T::class.java)

internal fun Shape.targetOrSelf(model: Model) = when (this) {
    is MemberShape -> model.expectShape(this.target)
    else -> this
}

inline fun <reified T : Trait> Shape.hasTrait(): Boolean = hasTrait(T::class.java)

inline fun <reified T : Trait> Shape.expectTrait(): T = expectTrait(T::class.java)

inline fun <reified T : Trait> Shape.getTrait(): T? = getTrait(T::class.java).orElse(null)

fun StructureShape.hasStreamingMember(model: Model): Boolean =
    this.allMembers.values.any { model.getShape(it.target).get().hasTrait<StreamingTrait>() }

fun ServiceShape.hasIdempotentTokenMember(model: Model) =
    this.operations.any { operationShapeId ->
        val operation = model.expectShape(operationShapeId) as OperationShape
        operation.input.isPresent &&
            model.expectShape(operation.input.get()).members().any { it.hasTrait(IdempotencyTokenTrait.ID.name) }
    }

val Shape.isDeprecated: Boolean
    get() = hasTrait<DeprecatedTrait>()

/**
 * Test if a shape represents a string enumeration shape
 */
val Shape.isEnum: Boolean
    get() = isStringShape && hasTrait<EnumTrait>()

/**
 * Test if a shape is an error.
 */
val Shape.isError: Boolean
    get() = hasTrait<ErrorTrait>()

/**
 * Test if a shape represents a Kotlin number type
 */
val Shape.isNumberShape: Boolean
    get() = this is NumberShape

/**
 * Test if a shape has the streaming trait applied.
 */
val Shape.isStreaming: Boolean
    get() = hasTrait<StreamingTrait>()

fun Shape.toUpperCamelCase(): String {
    return this.id.name.toUpperCamelCase()
}

fun Shape.defaultName(serviceShape: ServiceShape? = null): String {
    return serviceShape?.let {
        StringUtils.capitalize(id.getName(it))
    } ?: run {
        StringUtils.capitalize(this.id.name)
    }
}
fun MemberShape.defaultName(): String = memberName.toLowerCamelCase()
fun MemberShape.toLowerCamelCase(): String = this.memberName.toLowerCamelCase()
fun Shape.toLowerCamelCase(): String = this.id.name.toLowerCamelCase()

fun MemberShape.defaultValue(symbolProvider: SymbolProvider): String? {
    val targetSymbol = symbolProvider.toSymbol(this)
    return targetSymbol.defaultValue()
}

fun MemberShape.needsDefaultValueCheck(model: Model, symbolProvider: SymbolProvider): Boolean {
    if (this.isRequired()) {
        return false
    }

    val targetShape = model.expectShape(this.target)
    val isNotBoxed = !symbolProvider.toSymbol(this).isBoxed()
    val isPrimitiveShape = (targetShape.isNumberShape || targetShape.isBooleanShape)
    val defaultValueNotNull = this.defaultValue(symbolProvider) != null

    return isPrimitiveShape && isNotBoxed && defaultValueNotNull
}

fun MemberShape.isRequired(): Boolean {
    return (this.hasTrait<RequiredTrait>())
}

fun ServiceShape.nestedNamespaceType(symbolProvider: SymbolProvider): Symbol {
    val serviceSymbol = symbolProvider.toSymbol(this)
    return Symbol
        .builder()
        .name("${serviceSymbol.name}Types")
        .build()
}

fun Model.getNestedShapes(serviceShape: ServiceShape): Set<Shape> {
    return Selector
        .parse("service [id=${serviceShape.id}] ~> :is(structure, union, string [trait|enum]) :not(<-[input, output, error]-)")
        .select(this)
}

fun Model.getNestedErrors(serviceShape: ServiceShape): Set<StructureShape> {
    return Selector
        .parse("service[id=${serviceShape.id}] ~> structure[trait|error]")
        .select(this)
        .map { it as StructureShape }
        .toSet()
}

fun Model.getNestedShapes(memberShape: MemberShape): Set<Shape> {
    return Selector
        .parse("member [id='${memberShape.id}'] ~> *")
        .select(this)
}

fun Model.getNestedShapes(structureShape: StructureShape): Set<Shape> {
    return Selector
        .parse("structure[id='${structureShape.id}'] ~> *")
        .select(this)
}

fun Model.getOperations(serviceShape: ServiceShape): Set<OperationShape> {
    return Selector
        .parse("service[id='${serviceShape.id}'] ~> :is(operation)")
        .select(this) as Set<OperationShape>
}

fun Model.getErrorShapes(serviceShape: ServiceShape): Set<StructureShape> {
    return Selector
        .parse("service[id=${serviceShape.id}] ~> :is(structure[trait|error])")
        .select(this) as Set<StructureShape>
}

/**
 * Test if an operation input is an event stream
 */
fun OperationShape.isInputEventStream(model: Model): Boolean {
    val reqShape = model.expectShape<StructureShape>(input.get())
    return reqShape.hasEventStreamMember(model)
}

/**
 * Test if an operation output is an event stream
 */
fun OperationShape.isOutputEventStream(model: Model): Boolean {
    val respShape = model.expectShape<StructureShape>(output.get())
    return respShape.hasEventStreamMember(model)
}

/**
 * Test if a member targets an event stream
 */
fun Shape.hasEventStreamMember(model: Model): Boolean {
    val streamingMember = findStreamingMember(model) ?: return false
    val target = model.expectShape(streamingMember.target)
    return target.isUnionShape
}

/**
 * Returns the member of this structure targeted with streaming trait (if it exists).
 *
 * A structure must have at most one streaming member.
 */
fun Shape.findStreamingMember(model: Model): MemberShape? = findMemberWithTrait<StreamingTrait>(model)

inline fun <reified T : Trait> Shape.findMemberWithTrait(model: Model): MemberShape? =
    members().find { it.getMemberTrait(model, T::class.java).isPresent }

fun UnionShape.eventStreamEvents(model: Model): Collection<MemberShape> {
    if (!hasTrait<StreamingTrait>()) return members()

    return members().filterNot {
        val target = model.expectShape(it.target)
        target.isError
    }
}

fun UnionShape.eventStreamErrors(model: Model): Collection<MemberShape> {
    if (!hasTrait<StreamingTrait>()) return members()

    return members().filter {
        val target = model.expectShape(it.target)
        target.isError
    }
}
