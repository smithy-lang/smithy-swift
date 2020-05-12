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

import java.util.*
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.utils.StringUtils

class EnumGenerator(
    private val symbolProvider: SymbolProvider?,
    private val writer: SwiftWriter?,
    private val shape: UnionShape
) {

    fun render() {
        val symbol: Symbol = symbolProvider!!.toSymbol(shape)
        val enumTrait = shape.expectTrait(EnumTrait::class.java)
        writer!!.write("// Enum values for \$L", symbol.name).openBlock("enum $symbol.name {", "}") {
            for (definition in enumTrait.values) {
                val labelBuilder: StringBuilder = StringBuilder(symbol.name)
                val name: String? = if (definition.key != null) definition.key else definition.value.toString()
                for (part in name!!.split("(?U)\\W").toTypedArray()) {
                    labelBuilder.append(StringUtils.capitalize(part.toLowerCase(Locale.US)))
                }
                val label = labelBuilder.toString()
                // definition.getDocumentation().ifPresent(writer::writeDocs)
                writer.write("case ", label, "=", definition.value)
            }
        }.write("")
    }
}
