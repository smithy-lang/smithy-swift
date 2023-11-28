package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.codegen.core.TopologicalIndex
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.selector.PathFinder
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.customtraits.RecursiveUnionTrait
import software.amazon.smithy.swift.codegen.customtraits.SwiftBoxTrait

object UnionIndirectivizer {
    /**
     * Transform a model which may contain recursive shapes into a model annotated with [SwiftBoxTrait]
     *
     * When recursive shapes do NOT go through a List, Map, Union, or Set, they must be boxed in Swift. This function will
     * iteratively find loops & add the `SwiftBoxTrait` trait in a deterministic way until it reaches a fixed point.
     *
     * This function MUST be deterministic (always choose the same shapes to `Box`). If it is not, that is a bug. Even so
     * this function may cause backward compatibility issues in certain pathological cases where a changes to recursive
     * structures cause different members to be boxed. We may need to address these via customizations.
     */
    fun transform(model: Model): Model {
        val next = transformInner(model)
        return if (next == null) {
            model
        } else {
            transform(next)
        }
    }

    /**
     * If [model] contains a recursive loop that must be boxed, apply one instance of [SwiftBoxTrait] return the new model.
     * If [model] contains no loops, return null.
     */
    private fun transformInner(model: Model): Model? {
        // Execute 1-step of the boxing algorithm in the path to reaching a fixed point
        // 1. Find all the shapes that are part of a cycle
        // 2. Find all the loops that those shapes are part of
        // 3. Filter out the loops that go through a layer of indirection
        // 3. Pick _just one_ of the remaining loops to fix
        // 4. Select the member shape in that loop with the earliest shape id
        // 5. Box it.
        // (External to this function) Go back to 1.
        val index = TopologicalIndex(model)
        val recursiveUnions = index.recursiveShapes.filter { it.isUnionShape }
        println("Found ${recursiveUnions.count()} recursive unions")
        println("Names: ${recursiveUnions.map { it.defaultName() }}")
        val loops = recursiveUnions.map {
            shapeId -> index.getRecursiveClosure(shapeId)
        }
        val loopToFix = loops.firstOrNull { loop: Set<PathFinder.Path> ->
            !containsIndirection(loop.map { it.startShape })
        }

        return loopToFix?.let { loop: Set<PathFinder.Path> ->
            println("Fixing loop of ${loop.count()} shapes")
            check(loop.isNotEmpty())
            val unionPathToIndirectivize = loop.first { it.startShape.isUnionShape }
            val unionShapeToIndirectivize = unionPathToIndirectivize.startShape.asUnionShape().get()
            println("Indirectivizing union ${unionShapeToIndirectivize}")
            ModelTransformer.create().mapShapes(model) { shape ->
                if (shape.id == unionShapeToIndirectivize.id) {
                    println("Applying trait to union ${unionShapeToIndirectivize}")
                    shape.asUnionShape().get().toBuilder().addTrait(RecursiveUnionTrait()).build()
                } else {
                    shape
                }
            }
        }
    }

    /**
     * Check if a List<Shape> contains a shape which will use a pointer when represented in Swift, avoiding the
     * need to add more Boxes
     */
    private fun containsIndirection(loop: List<Shape>): Boolean {
        return loop.find {
            when {
                it is ListShape ||
                it is MapShape ||
                it is UnionShape && it.hasTrait<RecursiveUnionTrait>() ||
                it is StructureShape && it.hasTrait<SwiftBoxTrait>() ||
                it is SetShape -> true
                else -> false
            }
        } != null
    }
}
