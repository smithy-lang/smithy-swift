/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.UnionShape

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
 *     bear: Bear
 * }
 * ```
 *
 * The following code is generated:
 *
 * ```
 * enum Attacker {
 *     case lion(Lion?)
 *     case bear(Bear?)
 *     case sdkUnknown(String?)
 * }
 *
 */

class UnionGenerator(
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: UnionShape
) {

    val unionSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    fun render() {
        writer.putContext("union.name", unionSymbol.name)
        writer.writeShapeDocs(shape)
        writer.writeAvailableAttribute(shape)
        writer.openBlock("public enum \$union.name:L: Equatable {", "}\n") {
            shape.allMembers.values.forEach {
                writer.writeMemberDocs(model, it)
                val enumCaseName = symbolProvider.toMemberName(it)
                val enumCaseAssociatedType = symbolProvider.toSymbol(it)
                writer.write("case \$L(\$T)", enumCaseName, enumCaseAssociatedType)
            }
            // add the sdkUnknown case which will always be last
            writer.write("case sdkUnknown(String?)")
        }
        writer.removeContext("union.name")
    }
}
