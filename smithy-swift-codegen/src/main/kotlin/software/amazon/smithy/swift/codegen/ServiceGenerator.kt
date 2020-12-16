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
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

/*
* Generates a Swift protocol for the service
 */
class ServiceGenerator(
    settings: SwiftSettings,
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val delegator: SwiftDelegator,
    private val protocolGenerator: ProtocolGenerator? = null
) {
    private var service = settings.getService(model)
    private val serviceSymbol: Symbol by lazy {
        symbolProvider.toSymbol(service)
    }
    private val rootNamespace = settings.moduleName

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
            val operationName = op.camelCaseName()
            // Theoretically this shouldn't happen since we insert empty input/outputs for operations that don't have one or the other to allow for sdk evolution
            if (!op.input.isPresent || !op.output.isPresent) throw CodegenException("model should have been preprocessed to ensure operations always have an input or output shape: $op.id")

            val inputShape = opIndex.getInput(op).get()
            val inputShapeName = symbolProvider.toSymbol(inputShape).name
            val inputParam = "input: $inputShapeName"

            val outputShape = opIndex.getOutput(op).get()
            val outputShapeName = symbolProvider.toSymbol(outputShape).name
            val errorTypeName = getOperationErrorShapeName(op)

            val outputParam = "completion: @escaping (SdkResult<$outputShapeName, $errorTypeName>) -> Void"

            val paramTerminator = ", "

            writer.writeShapeDocs(op)

            val hasOutputStream = operationHasOutputStream(model, opIndex, op)
            val hasInputStream = operationHasInputStream(model, opIndex, op)
            val accessSpecifier = if (insideProtocol) "" else "public "
            if (!hasOutputStream && !hasInputStream) {
                writer.write(
                    "${accessSpecifier}func \$L(\$L${paramTerminator}\$L)",
                    operationName,
                    inputParam,
                    outputParam
                )
            } else if (hasInputStream) {
                writer.write(
                        "${accessSpecifier}func \$L(\$L${paramTerminator}streamSource: StreamSource, \$L)",
                        operationName,
                        inputParam,
                        outputParam
                )
            } else if (hasOutputStream) {
                writer.write(
                        "${accessSpecifier}func \$L(\$L${paramTerminator}streamSink: StreamSink, \$L)",
                        operationName,
                        inputParam,
                        outputParam
                )
            }
        }

        fun getOperationInputShapeName(symbolProvider: SymbolProvider, opIndex: OperationIndex, op: OperationShape): String {
            val inputShape = opIndex.getInput(op).get()
            return symbolProvider.toSymbol(inputShape).name
        }

        fun getOperationOutputShapeName(symbolProvider: SymbolProvider, opIndex: OperationIndex, op: OperationShape): String {
            val outputShape = opIndex.getOutput(op).get()
            return symbolProvider.toSymbol(outputShape).name
        }

        fun getOperationErrorShapeName(op: OperationShape): String {
            return "${op.defaultName()}Error"
        }

        private fun operationHasOutputStream(model: Model, opIndex: OperationIndex, op: OperationShape): Boolean {
            val outputShape = opIndex.getOutput(op)
            return outputShape.map { it.hasStreamingMember(model) }.orElse(false)
        }

        private fun operationHasInputStream(model: Model, opIndex: OperationIndex, op: OperationShape): Boolean {
            val inputShape = opIndex.getInput(op)
            return inputShape.map { it.hasStreamingMember(model) }.orElse(false)
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
     *      func getFoo(input: GetFooInput, completion: @escaping (SdkResult<GetFooOutput, GetFooError>) -> Void)
     * }
     * ```
     */
    private fun renderSwiftProtocol() {
        val topDownIndex = TopDownIndex.of(model)
        val operations = topDownIndex.getContainedOperations(service)
        val operationsIndex = OperationIndex.of(model)

        writer.writeShapeDocs(service)
        writer.openBlock("public protocol ${serviceSymbol.name}Protocol {")
            .call {
                    operations.forEach { op ->
                        renderOperationDefinition(model, symbolProvider, writer, operationsIndex, op, true)
                        renderOperationErrorEnum(op)
                    }
                }
            .closeBlock("}")
            .write("")
    }

    /*
        Renders the Operation Error enum
    */
    private fun renderOperationErrorEnum(
        op: OperationShape
    ) {
        val errorShapes = op.errors.map { model.expectShape(it) as StructureShape }.toSet().sorted()
        val operationErrorName = getOperationErrorShapeName(op)
        val operationErrorSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName.swift")
            .name(operationErrorName)
            .build()
        val unknownServiceErrorSymbol = protocolGenerator?.unknownServiceErrorSymbol ?: ProtocolGenerator.DefaultUnknownServiceErrorSymbol

        delegator.useShapeWriter(operationErrorSymbol) { writer ->
            writer.addImport(unknownServiceErrorSymbol)
            writer.openBlock("public enum $operationErrorName {", "}") {
                for (errorShape in errorShapes) {
                    val errorShapeName = symbolProvider.toSymbol(errorShape).name
                    writer.write("case \$L(\$L)", errorShapeName.decapitalize(), errorShapeName)
                }
                val unknownServiceErrorType = unknownServiceErrorSymbol.name
                writer.write("case unknown($unknownServiceErrorType)")
            }
        }
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
