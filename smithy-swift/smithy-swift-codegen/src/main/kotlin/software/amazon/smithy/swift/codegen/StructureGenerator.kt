/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.HttpErrorTrait
import software.amazon.smithy.model.traits.RetryableTrait

class StructureGenerator (
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: StructureShape,
    private val serviceId: String
) {

    private val sortedMembers: List<MemberShape> = shape.allMembers.values.sortedBy { symbolProvider.toMemberName(it) }
    private var byMemberShape: MutableMap<MemberShape, Pair<String, Symbol>> = mutableMapOf()

    init {
        for (member in sortedMembers) {
            val memberName = symbolProvider.toMemberName(member)
            val memberSymbol = symbolProvider.toSymbol(member)
            byMemberShape[member] = Pair(memberName, memberSymbol)
        }
    }

    private val structSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    fun render() {
        writer.putContext("struct.name", structSymbol.name)
        if (shape.hasTrait(ErrorTrait::class.java)) {
            renderErrorStructure()
        } else {
            renderNonErrorStructure()
        }
        writer.removeContext("struct.name")
    }

    /**
     * Generates an appropriate Swift type for a Smithy Structure shape without error trait.
     *
     * For example, given the following Smithy model:
     *
     * ```
     * namespace smithy.example
     *
     * structure Person {
     *     @required
     *     name: String,
     *     age: Integer,
     * }
     *
     * ```
     * We will generate the following:
     * ```
     * public struct Person {
     *     public let name: String
     *     public let age: Int?
     *     public init (
     *         name: String,
     *         age: int? = nil
     *     )
     *     {
     *         self.name = name
     *         self.age = age
     *     }
     * }
     * ```
     */
    private fun renderNonErrorStructure() {
        writer.writeShapeDocs(shape)
        writer.openBlock("public struct \$struct.name:L {")
            .call { generateStructMembers() }
            .write("")
            .call { generateInitializerForStructure() }
            .closeBlock("}")
            .write("")
    }

    private fun generateStructMembers() {
        sortedMembers.forEach {
            val (memberName, memberSymbol) = byMemberShape[it]!!
            writer.writeMemberDocs(model, it)
            writer.write("public let \$L: \$T", memberName, memberSymbol)
        }
    }

    private fun generateInitializerForStructure() {
        writer.openBlock("public init (", ")") {
            for ((index, member) in sortedMembers.withIndex()) {
                val (memberName, memberSymbol) = byMemberShape[member]!!
                val terminator = if (index == sortedMembers.size - 1) "" else ","
                writer.write("\$L: \$D$terminator", memberName, memberSymbol)
            }
        }

        writer.openBlock("{", "}") {
            sortedMembers.forEach {
                val (memberName, _) = byMemberShape[it]!!
                writer.write("self.\$1L = \$1L", memberName)
            }
        }
    }

    /**
     * Generates an appropriate Swift type for a Smithy Structure shape with error trait.
     *
     * For example, given the following Smithy model:
     *
     * ```
     * namespace smithy.example
     *
     * @error("client")
     * @retryable
     * @httpError(429)
     * structure ThrottlingError {
     *     @required
     *     message: String
     * }
     *
     * ```
     * We will generate the following:
     * ```
     * public struct ThrottlingError: Exception {
     *     public let isRetryable = true
     *     public let errorType = .client
     *     public let serviceName = "Example"
     *     public let httpErrorCode = 429
     *     public let message: String
     *
     *     public init (
     *         message: String
     *     )
     *     {
     *         self.message = message
     *     }
     * }
     * ```
     */
    private fun renderErrorStructure() {
        assert(shape.getTrait(ErrorTrait::class.java).isPresent)
        writer.writeShapeDocs(shape)
        //writer.addImport(structSymbol)

        writer.openBlock("public struct \$struct.name:L: Exception {")
            .call { generateStructMembersForErrorTrait() }
            .call { generateStructMembers() }
            .write("")
            .call { generateInitializerForStructure() }
            .closeBlock("}")
            .write("")
    }

    private fun generateStructMembersForErrorTrait() {
        val errorTrait: ErrorTrait = shape.getTrait(ErrorTrait::class.java).get()
        writer.write("public let errorType = .\$L", errorTrait.value)

        if (shape.getTrait(HttpErrorTrait::class.java).isPresent) {
            val httpErrorCode = shape.getTrait(HttpErrorTrait::class.java).get().code
            writer.write("public let httpErrorCode = \$L", httpErrorCode)
        }

        val isRetryable: Boolean = shape.getTrait(RetryableTrait::class.java).isPresent
        writer.write("public let isRetryable = \$L", isRetryable)

        writer.write("public let serviceName = \$L", serviceId)
    }
}
