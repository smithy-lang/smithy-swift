/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.shapes.ShapeType

interface MemberShapeEncodeGeneratable {
    fun render()
}

class MemberShapeEncodeConstants {
    companion object {
        val primitiveSymbols: MutableSet<ShapeType> = hashSetOf(
            ShapeType.INTEGER, ShapeType.BYTE, ShapeType.SHORT,
            ShapeType.LONG, ShapeType.FLOAT, ShapeType.DOUBLE, ShapeType.BOOLEAN
        )
        val floatingPointPrimitiveSymbols: MutableSet <ShapeType> = hashSetOf(
            ShapeType.FLOAT, ShapeType.DOUBLE
        )
    }
}

fun getDefaultValueOfShapeType(shapeType: ShapeType): Comparable<*> {
    return when (shapeType) {
        ShapeType.INTEGER, ShapeType.BYTE, ShapeType.SHORT, ShapeType.LONG -> 0
        ShapeType.FLOAT, ShapeType.DOUBLE -> 0.0
        else -> false // PrimitiveBoolean case
    }
}
