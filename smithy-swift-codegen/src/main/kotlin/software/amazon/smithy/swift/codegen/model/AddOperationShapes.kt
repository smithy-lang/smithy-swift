/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.AbstractShapeBuilder
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.SyntheticClone
import java.util.logging.Logger

/**
 * Ensures that each operation has a unique input and output shape.
 */
class AddOperationShapes {

    companion object {
        private val LOGGER = Logger.getLogger(javaClass.name)
        private const val SYNTHETIC_NAMESPACE = "smithy.swift.synthetic"

        // These suffixes are appended to the operation name to form input/output shape names
        private val inputSuffix = "OperationInput"
        private val outputSuffix = "OperationOutput"
        /**
         * Processes the given model and returns a new model ensuring service operation has a unique input and output
         * synthesized shape.
         *
         * @param model the model
         * @param serviceShape the service shape
         * @return a model with unique operation input and output shapes
         */
        fun execute(model: Model, serviceShape: ServiceShape, moduleName: String): Model {
            val topDownIndex: TopDownIndex = TopDownIndex.of(model)
            val operations = topDownIndex.getContainedOperations(serviceShape)
            val modelBuilder: Model.Builder = model.toBuilder()
            for (operation in operations) {
                val operationId = operation.id
                LOGGER.info("building unique input/output shapes for $operationId")
                val inputShape = operation.input
                    .map { shapeId ->
                        cloneOperationShape(
                            operationId, (model.expectShape(shapeId) as StructureShape),
                            inputSuffix
                        )
                    }
                    .orElseGet { emptyOperationStructure(operationId, inputSuffix, moduleName) }

                val outputShape = operation.output
                    .map { shapeId ->
                        cloneOperationShape(
                            operationId, (model.expectShape(shapeId) as StructureShape),
                            outputSuffix
                        )
                    }
                    .orElseGet { emptyOperationStructure(operationId, outputSuffix, moduleName) }

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

            val xmlName = shape.getTrait<XmlNameTrait>()?.value
            if (xmlName == null) {
                // If the operation shape doesn't define an explicit xml name,
                // then add a xml name trait set to the shape's original name.
                // This is necessary since we modify the shape's name.
                builder.addTrait(XmlNameTrait(shape.defaultName()))
            }

            return builder.build() as Shape
        }
    }
}
