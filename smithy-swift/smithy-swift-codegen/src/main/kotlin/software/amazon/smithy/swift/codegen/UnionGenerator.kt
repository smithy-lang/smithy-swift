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
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.ErrorTrait

/**
 * Generates an appropriate Swift type for a Smithy union shape
 *
 * Smithy unions are rendered as an Enum in Swift. Only a single member
 * can be set at any given time.
 *
 * For example, given the following Smithy model:
 *
 * ```
 * union Attacker {
 *     lion: Lion,
 *     tiger: Tiger,
 *     bear: Bear,
 * }
 * ```
 *
 * The following code is generated:
 *
 * ```
 * enum Attacker {
 *     case lion(Lion)
 *     case tiger(Tiger)
 *     case bear(Bear)
 * }
 */

class UnionGenerator(
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: UnionShape
) {
    fun render() {
        renderFrozenEnum()
    }

    /**
     * Renders a normal swift enum with associated values
     */
    private fun renderFrozenEnum() {

        val symbol: Symbol = symbolProvider.toSymbol(shape)

        //TODO:: write docs

        writer.openBlock("public struct \$L {", symbol.name)
        for (member in shape.allMembers.values) {
            val memberName = symbolProvider.toMemberName(member)
            // writer.writeMemberDocs(model, member)
            writer.write("public let \$L: \$T", memberName, symbolProvider.toSymbol(member))
        }
        writer.closeBlock("}").write("")
    }
}
