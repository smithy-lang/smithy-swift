package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.PaginatedIndex
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.protocoltests.traits.HttpResponseTestsTrait
import software.amazon.smithy.swift.codegen.customtraits.EquatableConformanceTrait
import software.amazon.smithy.swift.codegen.customtraits.TestEquatableConformanceTrait

/*
 * This transformer is used to add @equatableConformance custom trait to
 * Smithy structure shapes and Smithy union shapes only when necessary, which atm is for pagination tokens.
 *
 * E.g., if an operation uses pagination, then it has a corresponding @paginated trait with
 * inputToken and outputToken fields that specify names of member shapes. Because the SDK uses equivalence checking
 * on those tokens during pagination, all structure and union shapes nested under that member shape must have
 * Equatable conformance in codegen output. Swift counterparts of Smithy simple types conform to Equatable by default.
 *
 * Minimizing protocol conformance has significant benefits for compile time and binary size of the SDK.
 */
object EquatableConformanceTransformer {
    fun transform(model: Model, service: ServiceShape): Model {
        // First identify shapes which need to have Equatable applied to them in the SDK, and add the
        // EquatableConformanceTrait to them.  Currently, these are only shapes that are input/output
        // pagination tokens, and the shapes nested within them.
        //
        // Then identify shapes that only need to have Equatable applied to them in response protocol tests,
        // and that don't already have Equatable from the step above, and apply the TestEquatableConformanceTrait
        // to those shapes.
        val model1 = paginationTransformation(model, service)
        return responseTestTransformation(model1, service)
    }

    private fun paginationTransformation(model: Model, service: ServiceShape): Model {
        val paginationTokenMembers = mutableSetOf<MemberShape>()
        val paginatedIndex = PaginatedIndex.of(model)
        // Collect all member shapes used as inputToken or outputToken for paginated operations.
        for (op in service.allOperations) {
            val paginationInfo = paginatedIndex.getPaginationInfo(service.id, op.toShapeId())
            paginationInfo.ifPresent {
                paginationTokenMembers.add(it.inputTokenMember)
                paginationTokenMembers.addAll(it.outputTokenMemberPath)
            }
        }
        // Get all shapes nested within member shapes used as pagination tokens.
        val shapesToAddEquatableConformanceTraitTo = mutableSetOf<Shape>()
        for (tokenMemberShape in paginationTokenMembers) {
            val nestedShapes = model.getNestedShapes(tokenMemberShape)
            shapesToAddEquatableConformanceTraitTo.addAll(nestedShapes)
        }
        // Add @equatableConformance custom trait to all structure and union shapes
        // ...nested under the token member shapes.
        return ModelTransformer.create().mapShapes(model) { shape ->
            if (shapesToAddEquatableConformanceTraitTo.contains(shape)) {
                when (shape.type) {
                    ShapeType.STRUCTURE -> shape.asStructureShape().get().toBuilder().addTrait(EquatableConformanceTrait()).build()
                    ShapeType.UNION -> shape.asUnionShape().get().toBuilder().addTrait(EquatableConformanceTrait()).build()
                    else -> shape
                }
            } else {
                shape
            }
        }
    }

    private fun responseTestTransformation(model: Model, service: ServiceShape): Model {

        // Both operation shapes and error shapes may have the HttpResponseTestsTrait.
        // Find both types of shape with that trait for this service.
        val errorsWithResponseTests = model.getNestedErrors(service)
            .filter { it.hasTrait<HttpResponseTestsTrait>() }
        val outputsWithResponseTests = service.allOperations
            .map { model.expectShape(it) as OperationShape }
            .filter { it.hasTrait<HttpResponseTestsTrait>() }
            .map { model.expectShape(it.outputShape) as StructureShape }

        // Get all the shapes that need to have Equatable conformance added for testing,
        // and add them to the list
        var needsTestEquatableConformance = mutableSetOf<ShapeId>()
        (errorsWithResponseTests + outputsWithResponseTests).forEach {
            addToList(model, it, needsTestEquatableConformance)
        }

        // Transform the model by adding the TestEquatableConformanceTrait to shapes that need it
        // In a later SwiftIntegration, the conformance will be code-generated
        return ModelTransformer.create().mapShapes(model) { shape ->
            if (!needsTestEquatableConformance.contains(shape.id)) {
                // If the shape doesn't need test equatable conformance, leave it unchanged
                shape
            } else if (shape.hasTrait<EquatableConformanceTrait>()) {
                // If the shape already has equatable conformance, leave it unchanged
                shape
            } else {
                // If the shape is a structure or union, add the TestEquatableConformanceTrait to it
                // All other shape types don't need to have Equatable generated for them
                when (shape.type) {
                    ShapeType.STRUCTURE -> shape.asStructureShape().get().toBuilder().addTrait(TestEquatableConformanceTrait()).build()
                    ShapeType.UNION -> shape.asUnionShape().get().toBuilder().addTrait(TestEquatableConformanceTrait()).build()
                    else -> shape
                }
            }
        }
    }

    // Adds the ShapeIds for the passed structure and all of its nested structures or unions
    // to the passed list.
    private fun addToList(model: Model, shape: StructureShape, list: MutableSet<ShapeId>) {
        list.add(shape.id)
        model.getNestedShapes(shape).forEach { nested ->
            if (nested.isStructureShape || nested.isUnionShape) {
                list.add(nested.id)
            }
        }
    }
}
