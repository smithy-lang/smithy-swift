/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.swift.codegen.customtraits.NestedTrait
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.nestedNamespaceType

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
    private val shape: UnionShape,
    private val settings: SwiftSettings
) {

    val unionSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    fun render() {
        writer.putContext("union.name", unionSymbol.name)
        val isNestedType = shape.hasTrait<NestedTrait>()
        if (isNestedType) {
            val service = model.expectShape<ServiceShape>(settings.service)
            writer.openBlock("extension ${service.nestedNamespaceType(symbolProvider)} {", "}") {
                renderUnion()
            }
        } else {
            renderUnion()
        }
        writer.removeContext("union.name")
    }

    fun renderUnion() {
        writer.writeShapeDocs(shape)
        writer.writeAvailableAttribute(model, shape)
        val indirectKeywordIfNeeded = if (needsIndirectKeyword(unionSymbol.name, shape)) "indirect " else ""
        val hashable = hashableIfPossible()
        writer.openBlock("public ${indirectKeywordIfNeeded}enum \$union.name:L: \$T$hashable {", "}\n", SwiftTypes.Protocols.Equatable) {
            shape.allMembers.values.forEach {
                writer.writeMemberDocs(model, it)
                val enumCaseName = symbolProvider.toMemberName(it)
                val enumCaseAssociatedType = symbolProvider.toSymbol(it)
                writer.write("case \$L(\$L)", enumCaseName, enumCaseAssociatedType)
            }
            // add the sdkUnknown case which will always be last
            writer.write("case sdkUnknown(\$T)", SwiftTypes.String)
        }
    }

    fun hashableIfPossible(): String {
        shape.allMembers.values.forEach {
            val enumCaseAssociatedType = symbolProvider.toSymbol(it)
            if (enumCaseAssociatedType.name != "String") {
                return ""
            }
        }
        return ", ${SwiftTypes.Protocols.Hashable.fullName}"
    }

    private fun needsIndirectKeyword(unionSymbolName: String, shape: UnionShape): Boolean {
        val membersReferencingUnion = shape.allMembers.values.filter {
            (symbolProvider.toSymbol(it).name).equals(unionSymbolName)
        }
        return membersReferencingUnion.isNotEmpty()
    }
}
