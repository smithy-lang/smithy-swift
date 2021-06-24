package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.loader.Prelude
import software.amazon.smithy.model.neighbor.RelationshipType
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.model.hasTrait

object HashableShapeTransformer {

    fun transform(model: Model): Model {
        val next = transformInner(model)
        return if (next == null) {
            model
        } else {
            transform(next)
        }
    }

    private fun transformInner(model: Model) : Model? {
        //find all the shapes in this models shapes that have a struct shape contained within a list or set and don't already have the trait
        //find all the other shapes referencing that shape and mark with hashable.
        val allShapesNeedingHashable = mutableSetOf<Shape>()
        val shapesNeedingHashable = model.shapes().filter { isHashable(model, it) }
        shapesNeedingHashable.forEach {allShapesNeedingHashable.add(it)}
        val walker = Walker(model)

        // walk all the shapes in the set and find all other
        // structs in the graph from that shape that are nested

        allShapesNeedingHashable.forEach { shape ->
            walker.iterateShapes(shape) { relationship ->
                when (relationship.relationshipType) {
                    RelationshipType.STRUCTURE_MEMBER,
                    RelationshipType.MEMBER_TARGET -> true
                    else -> false
                }
            }.forEach {
                if (it is StructureShape && !it.hasTrait<HashableTrait>()) {
                    allShapesNeedingHashable.add(it)
                }
            }
        }

        if(allShapesNeedingHashable.isEmpty()) {
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

    private fun isHashable(model: Model, shape: Shape): Boolean {
        return if (shape is StructureShape && !Prelude.isPreludeShape(shape)) {
            val allCollectionShapes = model.setShapes.filter { !Prelude.isPreludeShape(it) }
            allCollectionShapes.any { it.member.target == shape.toShapeId() } && !shape.hasTrait<HashableTrait>()
        } else {
            false
        }
    }

}