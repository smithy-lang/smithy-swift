/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.DocumentationTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.toLowerCamelCase

/*
* Generates a Swift protocol for the service
 */
class ServiceGenerator(
    settings: SwiftSettings,
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val delegator: SwiftDelegator,
    private val protocolGenerator: ProtocolGenerator? = null,
    private val protocolGenerationContext: ProtocolGenerator.GenerationContext?
) {
    private var service = settings.getService(model)
    private val serviceSymbol: Symbol by lazy {
        symbolProvider.toSymbol(service)
    }

    companion object {
        /**
         * Renders the definition of operation
         */
        fun renderOperationDefinition(
            model: Model,
            symbolProvider: SymbolProvider,
            writer: SwiftWriter,
            opIndex: OperationIndex,
            op: OperationShape,
            insideProtocol: Boolean = false
        ) {
            val operationName = op.toLowerCamelCase()
            // Theoretically this shouldn't happen since we insert empty input/outputs for operations that don't have one or the other to allow for sdk evolution
            if (!op.input.isPresent || !op.output.isPresent) throw CodegenException("model should have been preprocessed to ensure operations always have an input or output shape: $op.id")

            val inputShape = opIndex.getInput(op).get()
            val inputShapeName = symbolProvider.toSymbol(inputShape).name
            val inputParam = "input: $inputShapeName"
            val outputShape = opIndex.getOutput(op).get()
            val outputShapeName = symbolProvider.toSymbol(outputShape).name

            renderOperationDoc(model, op, writer)

            val accessSpecifier = if (insideProtocol) "" else "public "

            writer.write(
                "${accessSpecifier}func \$L(\$L) async throws -> \$L",
                operationName,
                inputParam,
                outputShapeName
            )
        }

        /**
         * Helper method for generating in-line documentation for operation
         */
        private fun renderOperationDoc(model: Model, op: OperationShape, writer: SwiftWriter) {
            writer.writeShapeDocs(op)
            writer.writeAvailableAttribute(model, op)

            writer.writeSingleLineDocs { write("") }
            writer.writeSingleLineDocs { write("- Parameter ${op.inputShape.name} : ${retrieveMemberShapeDoc(op.inputShape, model)}") }

            writer.writeSingleLineDocs { write("") }
            writer.writeSingleLineDocs { write("- Returns: `${op.outputShape.name}` : ${retrieveMemberShapeDoc(op.outputShape, model)}") }

            if (op.errors.size > 0) {
                writer.writeSingleLineDocs { write("") }
                writer.writeSingleLineDocs { write("- Throws:") }
                for (error in op.errors) {
                    writer.writeSingleLineDocs { write("") }
                    writer.writeSingleLineDocs { write ("- `${error.name}` : ${retrieveMemberShapeDoc(error.toShapeId(), model)}") }
                }
            }
        }

        /**
         * Helper method to grab documentation for operation's member shapes (input, output, error(s)
         */
        private fun retrieveMemberShapeDoc(shapeId : ShapeId, model : Model) : String {
            val docTrait = model.getShape(shapeId).get().getTrait(DocumentationTrait::class.java).getOrNull()
            return when {
                docTrait == null -> "[no documentation found]"
                else -> docTrait.value
            }
        }
    }

    fun render() {
        // add imports
        writer.addImport(serviceSymbol)

        // generate protocol
        renderSwiftProtocol()
    }

    /**
     * Generates an appropriate Swift Protocol for a Smithy Service shape.
     *
     * For example, given the following Smithy model:
     *
     * ```
     * namespace smithy.example
     *
     * use aws.protocols#awsJson1_1
     *
     *   @awsJson1_1
     *  service Example {
     *   version: "1.0.0",
     *   operations: [GetFoo]
     *   }
     *
     *  operation GetFoo {
     *   input: GetFooInput,
     *   output: GetFooOutput,
     *   errors: [GetFooError]
     *   }
     *
     * ```
     * We will generate the following:
     * ```
     * public protocol ExampleServiceProtocol {
     *      func getFoo(input: GetFooInput) async throws -> GetFooResponse
     * }
     * ```
     */
    private fun renderSwiftProtocol() {
        val topDownIndex = TopDownIndex.of(model)
        val operations = topDownIndex.getContainedOperations(service)
        val operationsIndex = OperationIndex.of(model)

        writer.writeShapeDocs(service)
        writer.writeAvailableAttribute(model, service)
        writer.openBlock("public protocol ${serviceSymbol.name}Protocol {")
            .call {
                operations.forEach { op ->
                    renderOperationDefinition(model, symbolProvider, writer, operationsIndex, op, true)
                }
            }
            .closeBlock("}")
            .write("")
    }
}

/**
 * An extension to see if a structure shape has a the streaming trait*.
 *
 * @model model is the smithy model.
 * @return true if has the streaming trait on itself or its target.
 */
fun StructureShape.hasStreamingMember(model: Model): Boolean {
    return this.allMembers.values.any {
        val streamingTrait = StreamingTrait::class.java
        it.hasTrait(streamingTrait) || model.getShape(it.target).get().hasTrait(streamingTrait)
    }
}
