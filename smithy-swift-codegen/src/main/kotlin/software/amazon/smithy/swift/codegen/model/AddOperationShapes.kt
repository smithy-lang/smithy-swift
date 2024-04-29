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
import software.amazon.smithy.model.shapes.OperationShape

var operationCount = 0
var requestCount = 0
var inputCount = 0
var otherCount = 0
var dontStartWithOperation = mutableListOf<String>()

/**
 * Ensures that each operation has a unique input and output shape.
 */
class AddOperationShapes {

    private enum class IO {
        INPUT, OUTPUT
    }

    companion object {
        private val LOGGER = Logger.getLogger(AddOperationShapes::class.java.name)
        private const val SYNTHETIC_NAMESPACE = "smithy.swift.synthetic"

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
                LOGGER.info("building unique input/output shapes for $operation.id")

                val inputUniqueName = findUniqueName(model, operation, IO.INPUT)
                val inputShape = operation.input.map { shapeId ->
                    val structureShape = model.expectShape<StructureShape>(shapeId)
                    cloneOperationShape(structureShape, inputUniqueName)
                }.orElseGet { emptyOperationStructure(moduleName, inputUniqueName) }

                val outputUniqueName = findUniqueName(model, operation, IO.OUTPUT)
                val outputShape = operation.output.map { shapeId ->
                    val structureShape = model.expectShape<StructureShape>(shapeId)
                    cloneOperationShape(structureShape, outputUniqueName)
                }.orElseGet { emptyOperationStructure(moduleName, outputUniqueName) }

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

            println("Has Request: $requestCount.  Input: $inputCount  Other: $otherCount Operation: $operationCount")
            println("Exceptions: $dontStartWithOperation")
            return modelBuilder.build()
        }

        private fun emptyOperationStructure(moduleName: String, uniqueName: String): StructureShape {
            val shapeID = ShapeId.fromParts(moduleName, uniqueName)
            return StructureShape.builder().id(shapeID).build()
        }

        private fun cloneOperationShape(
            structureShape: StructureShape,
            uniqueName: String
        ): StructureShape {
            return cloneShape(structureShape, uniqueName) as StructureShape
        }

        private fun findUniqueName(
            model: Model,
            operation: OperationShape,
            structure: IO,
        ): String {
            // These suffixes are appended to the operation name to form input/output shape names
            val inputSuffixes = listOf("Input", "OperationInput", "OpInput", "Request")
            val outputSuffixes = listOf("Output", "OperationOutput", "OpOutput", "Response")
            val suffixes = inputSuffixes.takeIf { structure == IO.INPUT } ?: outputSuffixes

            val shapeIDToReplace = operation.inputShape.takeIf { structure == IO.INPUT } ?: operation.outputShape

            if (structure == IO.INPUT) {
                if (shapeIDToReplace.name.endsWith("Request")) {
                    requestCount++
                } else if (shapeIDToReplace.name.endsWith("Input")) {
                    inputCount++
                } else {
                    otherCount++
                }
                if (!shapeIDToReplace.name.startsWith(operation.id.name)) {
                    operationCount++
                    dontStartWithOperation.add(shapeIDToReplace.name)
                }
            }
            suffixes.forEach { suffix ->
                val nameCandidate = operation.id.name + suffix
                val shapeIDCandidate = ShapeId.from(operation.id.namespace + "#" + nameCandidate)
                if (model.getShape(shapeIDCandidate).isPresent && shapeIDCandidate != shapeIDToReplace) {
                    println("DETECTED CLASH: $shapeIDToReplace to $shapeIDCandidate")
                    return@forEach
                }
                return nameCandidate
            }
            throw Exception("Unable to find a deconflicted input/output name for ${operation.id}")
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
