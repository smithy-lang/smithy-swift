/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.loader.Prelude
import software.amazon.smithy.model.neighbor.RelationshipType
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.customtraits.HashableTrait

object HashableShapeTransformer {

    fun transform(model: Model): Model {
        val next = transformInner(model)
        return if (next == null) {
            model
        } else {
            transform(next)
        }
    }

    private fun transformInner(model: Model): Model? {
        // find all the shapes in this models shapes that have a struct shape contained within a set and don't already have the trait
        val allShapesNeedingHashable = mutableSetOf<Shape>()
        model.shapes().filter { needsHashableTrait(model, it) }
            .forEach { allShapesNeedingHashable.add(it) }
        // find all the other shapes referencing that shape and mark with hashable.
        allShapesNeedingHashable.addAll(getNestedTypesNeedingHashable(model, allShapesNeedingHashable))

        if (allShapesNeedingHashable.isEmpty()) {
            return null
        }

        return ModelTransformer.create().mapShapes(model) { shape ->
            if (allShapesNeedingHashable.contains(shape)) {
                shape.asStructureShape().get().toBuilder().addTrait(HashableTrait()).build()
            } else {
                shape
            }
        }
    }

    private fun getNestedTypesNeedingHashable(model: Model, shapes: Set<Shape>): Set<Shape> {
        val nestedTypes = mutableSetOf<Shape>()
        val walker = Walker(model)
        // walk all the shapes in the set and find all other
        // structs in the graph from that shape that are nested
        shapes.forEach { shape ->
            walker.iterateShapes(shape) { relationship ->
                when (relationship.relationshipType) {
                    RelationshipType.STRUCTURE_MEMBER,
                    RelationshipType.MEMBER_TARGET -> true
                    else -> false
                }
            }.forEach {
                if (it is StructureShape && !it.hasTrait<HashableTrait>()) {
                    nestedTypes.add(it)
                }
            }
        }
        return nestedTypes
    }

    private fun needsHashableTrait(model: Model, shape: Shape): Boolean {
        return if (shape is StructureShape && !Prelude.isPreludeShape(shape)) {
            val allCollectionShapes = model.setShapes.filter { !Prelude.isPreludeShape(it) }
            allCollectionShapes.any { it.member.target == shape.toShapeId() } && !shape.hasTrait<HashableTrait>()
        } else {
            false
        }
    }
}
