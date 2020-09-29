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
import software.amazon.smithy.codegen.core.TopologicalIndex
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.HttpErrorTrait
import software.amazon.smithy.model.traits.RetryableTrait

fun MemberShape.isRecursiveMember(index: TopologicalIndex): Boolean {
    var isRecursiveMember = false

    val shapeId = toShapeId()
    // handle recursive types
    val loop = index.getRecursiveClosure(shapeId)
    if (loop.size > 0) {
        // loop through set of paths and then array of paths to find if current member matches a member in that list
        // if it does it is a recursive member that needs to be boxed as so
        isRecursiveMember = loop.any { path -> path.endShape.id == shapeId }
    }
    return isRecursiveMember
}

class StructureGenerator(
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: StructureShape
) {

    private val membersSortedByName: List<MemberShape> = shape.allMembers.values.sortedBy { symbolProvider.toMemberName(it) }
    private var memberShapeDataContainer: MutableMap<MemberShape, Pair<String, Symbol>> = mutableMapOf()
    private val topologicalIndex = TopologicalIndex.of(model)

    init {
        for (member in membersSortedByName) {
            val memberName = symbolProvider.toMemberName(member)
            val memberSymbol = symbolProvider.toSymbol(member)
            memberShapeDataContainer[member] = Pair(memberName, memberSymbol)
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
     * If the structure is a recursive nested type it will generate a boxed member Box<T>.
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
        membersSortedByName.forEach {
            val isRecursiveMember = it.isRecursiveMember(topologicalIndex)
            val shape = model.expectShape(it.target)
            val (memberName, memberSymbol) = memberShapeDataContainer.getOrElse(it) { return@forEach }
            writer.writeMemberDocs(model, it)

            // if shape is a collection or map shape which are COW in swift or is not recursive apply member normally
            if ((shape is CollectionShape || shape is MapShape) || !isRecursiveMember) {
                // apply member normally
                writer.write("public let \$L: \$T", memberName, memberSymbol)
            } else {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.getPackageName())
                val symbol = if (isRecursiveMember) memberSymbol.recursiveSymbol() else memberSymbol
                writer.write("public let \$L: \$T", memberName, symbol)
            }
        }
    }

    private fun generateInitializerForStructure() {
        val hasErrorTrait = shape.getTrait(HttpErrorTrait::class.java).isPresent
        val hasMembers = membersSortedByName.isNotEmpty()

        // TODO:: handle the rendering of error and normal structures more separately
        if (hasErrorTrait || hasMembers) {
            writer.openBlock("public init (", ")") {
                if (hasErrorTrait) {
                    writer.write("httpResponse: HttpResponse" + (if (hasMembers) "," else ""))
                }

                for ((index, member) in membersSortedByName.withIndex()) {
                    val (memberName, memberSymbol) = memberShapeDataContainer.getOrElse(member) { Pair(null, null) }
                    if (memberName == null || memberSymbol == null) continue
                    val terminator = if (index == membersSortedByName.size - 1) "" else ","
                    val isRecursive = member.isRecursiveMember(topologicalIndex)
                    val symbolToUse = if (isRecursive) memberSymbol.recursiveSymbol() else memberSymbol
                    writer.write("\$L: \$D$terminator", memberName, symbolToUse)
                }
            }
            writer.openBlock("{", "}") {
                if (hasErrorTrait) {
                    writer.write("self.httpResponse = httpResponse")
                }
                membersSortedByName.forEach {
                    val (memberName, _) = memberShapeDataContainer.getOrElse(it) { return@forEach }
                    writer.write("self.\$1L = \$1L", memberName)
                }
            }
        } else if (!hasErrorTrait && !hasMembers) {
            writer.write("public init() {}")
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
     * public struct ThrottlingError: HttpOperationError {
     *     public var httpResponse: HttpResponse
     *     public var retryable = true
     *     public var type = .client
     *     public var message: String
     *
     *     public init (
     *         message: String,
     *         httpResponse: HttpResponse
     *     )
     *     {
     *         self.httpResponse = httpResponse
     *         self.message = message
     *     }
     * }
     * ```
     */
    private fun renderErrorStructure() {
        assert(shape.getTrait(ErrorTrait::class.java).isPresent)
        writer.writeShapeDocs(shape)
        writer.addImport(structSymbol)

        var errorProtocol = "OperationError" // just a placeholder for now
        if (shape.getTrait(HttpErrorTrait::class.java).isPresent) {
            errorProtocol = "HttpOperationError"
        }
        writer.putContext("error.protocol", errorProtocol)

        writer.openBlock("public struct \$struct.name:L: \$error.protocol:L {")
            .call { generateErrorStructMembers() }
            .write("")
            .call { generateInitializerForStructure() }
            .closeBlock("}")
            .write("")

        writer.removeContext("error.protocol")
    }

    private fun generateErrorStructMembers() {
        val errorTrait: ErrorTrait = shape.getTrait(ErrorTrait::class.java).get()
        if (shape.getTrait(HttpErrorTrait::class.java).isPresent) {
            writer.write("public var httpResponse: HttpResponse")
        }

        val isRetryable: Boolean = shape.getTrait(RetryableTrait::class.java).isPresent
        writer.write("public var retryable = \$L", isRetryable)

        writer.write("public var type: ErrorType = .\$L", errorTrait.value)

        membersSortedByName.forEach {
            val (memberName, memberSymbol) = memberShapeDataContainer.getOrElse(it) { return@forEach }
            writer.writeMemberDocs(model, it)
            writer.write("public var \$L: \$T", memberName, memberSymbol)
        }
    }
}
