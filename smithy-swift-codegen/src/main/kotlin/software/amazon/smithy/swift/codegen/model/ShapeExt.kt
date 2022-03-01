
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
import software.amazon.smithy.model.traits.DeprecatedTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.model.traits.RequiredTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.model.traits.Trait
import software.amazon.smithy.swift.codegen.getOrNull
import software.amazon.smithy.utils.StringUtils
import kotlin.streams.toList

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

inline fun <reified T : Trait> Shape.getTrait(): T? = getTrait(T::class.java).getOrNull()

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

val Shape.isEnum: Boolean
    get() = isStringShape && hasTrait<EnumTrait>()

val Shape.isError: Boolean
    get() = hasTrait<ErrorTrait>()

val Shape.isNumberShape: Boolean
    get() = this is NumberShape

fun Shape.capitalizedName(): String {
    return StringUtils.capitalize(this.id.name)
}

fun Shape.defaultName(serviceShape: ServiceShape? = null): String {
    return serviceShape?.let {
        StringUtils.capitalize(id.getName(it))
    } ?: run {
        StringUtils.capitalize(this.id.name)
    }
}
fun MemberShape.camelCaseName(): String = StringUtils.uncapitalize(this.memberName)
fun Shape.camelCaseName(): String = StringUtils.uncapitalize(this.id.name)

fun MemberShape.defaultValue(symbolProvider: SymbolProvider): String? {
    val targetSymbol = symbolProvider.toSymbol(this)
    return targetSymbol.defaultValue()
}

fun MemberShape.needsDefaultValueCheck(model: Model, symbolProvider: SymbolProvider): Boolean {
    if (this.hasTrait<RequiredTrait>()) {
        return false
    }

    val targetShape = model.expectShape(this.target)
    val isNotBoxed = !symbolProvider.toSymbol(this).isBoxed()
    val isPrimitiveShape = (targetShape.isNumberShape || targetShape.isBooleanShape)
    val defaultValueNotNull = this.defaultValue(symbolProvider) != null

    return isPrimitiveShape && isNotBoxed && defaultValueNotNull
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
        .parse("service [id=${serviceShape.id }] ~> :is(structure,union, string [trait|enum]) :not(<-[input, output, error]-)")
        .select(this)
}
