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
    fun transform(model: Model): Model {
        // Transform the model, adding one `RecursiveTrait` at a time, until no more unmarked recursive unions remain.
        val next = transformInner(model)
        return if (next == null) {
            model
        } else {
            transform(next)
        }
    }

    // Find the recursive unions, then mark one as recursive.  Only mark one, then
    // return so the model can be re-evaluated.
    private fun transformInner(model: Model): Model? {
        val index = TopologicalIndex(model)
        val recursiveUnions = index.recursiveShapes.filter { it.isUnionShape }
        val loops = recursiveUnions.map {
            shapeId -> index.getRecursiveClosure(shapeId)
        }
        val loopToFix = loops.firstOrNull { loop: Set<PathFinder.Path> ->
            !containsIndirection(loop.map { it.startShape })
        }

        return loopToFix?.let { loop: Set<PathFinder.Path> ->
            check(loop.isNotEmpty())
            val unionPathToIndirectivize = loop.first { it.startShape.isUnionShape }
            val unionShapeToIndirectivize = unionPathToIndirectivize.startShape.asUnionShape().get()
            ModelTransformer.create().mapShapes(model) { shape ->
                if (shape.id == unionShapeToIndirectivize.id) {
                    shape.asUnionShape().get().toBuilder().addTrait(RecursiveUnionTrait()).build()
                } else {
                    shape
                }
            }
        }
    }

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
