/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.AbstractShapeBuilder
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import java.util.logging.Logger

/**
 * Ensures that each operation has a unique input and output shape.
 */
class AddOperationShapes {

    companion object {
        private val LOGGER = Logger.getLogger(javaClass.name)
        private const val SYNTHETIC_NAMESPACE = "smithy.swift.synthetic"
        /**
         * Processes the given model and returns a new model ensuring service operation has an unique input and output
         * synthesized shape.
         *
         * @param model the model
         * @param serviceShapeId the service shape
         * @return a model with unique operation input and output shapes
         */
        fun execute(model: Model, serviceShape: ServiceShape, moduleName: String): Model {
            val topDownIndex: TopDownIndex = TopDownIndex.of(model)
            val operations = topDownIndex.getContainedOperations(serviceShape)
            val modelBuilder: Model.Builder = model.toBuilder()
            for (operation in operations) {
                val operationId = operation.id
                LOGGER.info("building unique input/output shapes for $operationId")
                // TODO: MUST FIX BEFORE SHIPPING. check to see if new synthetic input or output shapes conflict with any other shapes
                // in the model by walking the model and fail code generation
                val inputShape = operation.input
                    .map { shapeId ->
                        cloneOperationShape(
                            operationId, (model.expectShape(shapeId) as StructureShape),
                            "Input"
                        )
                    }
                    .orElseGet { emptyOperationStructure(operationId, "Input", moduleName) }

                val outputShape = operation.output
                    .map { shapeId ->
                        cloneOperationShape(
                            operationId, (model.expectShape(shapeId) as StructureShape),
                            "OutputResponse"
                        )
                    }
                    .orElseGet { emptyOperationStructure(operationId, "OutputResponse", moduleName) }

                // Add new input/output to model
                modelBuilder.addShape(inputShape)
                modelBuilder.addShape(outputShape)

                // Update operation model with the input/output shape ids
                modelBuilder.addShape(
                    operation.toBuilder()
                        .input(inputShape.toShapeId())
                        .output(outputShape.toShapeId())
                        .build()
                )
            }
            return modelBuilder.build()
        }

        private fun emptyOperationStructure(opShapeId: ShapeId, suffix: String, moduleName: String): StructureShape {
            return StructureShape.builder()
                .id(
                    ShapeId.fromParts(
                        moduleName,
                        opShapeId.name + suffix
                    )
                )
                .build()
        }

        private fun cloneOperationShape(
            operationShapeId: ShapeId,
            structureShape: StructureShape,
            suffix: String
        ): StructureShape {
            return cloneShape(structureShape, operationShapeId.name + suffix) as StructureShape
        }

        private fun cloneShape(shape: Shape, cloneShapeName: String): Shape {

            val cloneShapeId = ShapeId.fromParts(SYNTHETIC_NAMESPACE, cloneShapeName)

            var builder: AbstractShapeBuilder<*, *> = Shape.shapeToBuilder(shape)
            builder = builder.id(cloneShapeId).addTrait(
                SyntheticClone.builder()
                    .archetype(shape.id).build()
            )

            shape.members().forEach { memberShape ->
                builder.addMember(
                    memberShape.toBuilder()
                        .id(cloneShapeId.withMember(memberShape.memberName))
                        .build()
                )
            }
            return builder.build() as Shape
        }
    }
}
