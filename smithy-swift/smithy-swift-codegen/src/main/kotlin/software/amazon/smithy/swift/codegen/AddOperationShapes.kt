/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
 */

package software.amazon.smithy.swift.codegen

import java.util.*
import java.util.logging.Logger
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape

/**
 * Ensures that each operation has a unique input and output shape.
 */
// TODO: decide between this approach vs additive approach with inputs and fix outputs to create synthetic outputs to avoid possible future added outputs.
public final class AddOperationShapes {

    companion object {
        private val LOGGER = Logger.getLogger(javaClass.name)
        /**
         * Processes the given model and returns a new model ensuring service operation has an unique input and output
         * synthesized shape.
         *
         * @param model the model
         * @param serviceShapeId the service shape
         * @return a model with unique operation input and output shapes
         */
        fun execute(model: Model, serviceShape: ServiceShape, moduleName: String): Model {
            val topDownIndex: TopDownIndex =
                model.getKnowledge(TopDownIndex::class.java)
            val opIndex: OperationIndex = model.getKnowledge(OperationIndex::class.java)
            val operations = topDownIndex.getContainedOperations(serviceShape)
            val modelBuilder: Model.Builder = model.toBuilder()
            for (operation in operations) {
                val operationId = operation.id
                LOGGER.info("building unique input/output shapes for $operationId")

                val inputShape = opIndex.getInput(operation)
                    .orElseGet {
                        emptyOperationStructure(operationId, "Input", moduleName)
                    }

                val outputShape = opIndex.getOutput(operation)
                    .orElseGet {
                        emptyOperationStructure(operationId, "Output", moduleName)
                    }

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
    }
}
