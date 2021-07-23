
/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
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
import software.amazon.smithy.swift.codegen.defaultValue
import software.amazon.smithy.swift.codegen.getOrNull
import software.amazon.smithy.swift.codegen.isBoxed
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

fun MemberShape.defaultValue(symbolProvider: SymbolProvider): String? {
    val targetSymbol = symbolProvider.toSymbol(this)
    return targetSymbol.defaultValue()
}

fun MemberShape.needsEncodingCheck(model: Model, symbolProvider: SymbolProvider): Boolean {
    val targetShape = model.expectShape(this.target)
    val targetSymbol = symbolProvider.toSymbol(this)

    return if ((targetShape.isNumberShape || targetShape.isBooleanShape) && !targetSymbol.isBoxed() && this.defaultValue(symbolProvider) != null) {
        when (this.hasTrait<RequiredTrait>()) {
            true -> false // always serialize a required member even if it's the default
            else -> true
        }
    } else {
        false
    }
}
