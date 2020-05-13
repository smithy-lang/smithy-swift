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
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.ErrorTrait

class StructureGenerator(
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: StructureShape
) {
    fun render() {
        if (!shape.hasTrait(ErrorTrait::class.java)) {
            renderStructure()
        }
        // TODO: render error structure
    }

    /**
     * Renders a normal, non-error structure.
     */
    private fun renderStructure() {
        val symbol: Symbol = symbolProvider.toSymbol(shape)
        writer.writeShapeDocs(shape)
        writer.openBlock("public struct \$L {", symbol.name)

        // write structure properties as let properties for immutability
        for (member in shape.allMembers.values) {
            val memberName = symbolProvider.toMemberName(member)
            writer.writeMemberDocs(model, member)
            writer.write("public let \$L: \$T", memberName, symbolProvider.toSymbol(member))
        }
        writer.write("")
        // write struct constructor
        writer.openBlock("public init (", ")") {
            shape.allMembers.values.forEachIndexed { index, member ->
                val terminator = if (index == shape.allMembers.values.count() - 1) "" else ","
                writer.write("\$L: \$D$terminator", symbolProvider.toMemberName(member), symbolProvider.toSymbol(member))
            }
        }

        writer.openBlock("{", "}") {
            for (member in shape.allMembers.values) {
                val memberName = symbolProvider.toMemberName(member)
                writer.write("self.\$1L = \$1L", memberName)
            }
        }

        writer.closeBlock("}").write("")
    }
}
