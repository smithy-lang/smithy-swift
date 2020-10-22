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
