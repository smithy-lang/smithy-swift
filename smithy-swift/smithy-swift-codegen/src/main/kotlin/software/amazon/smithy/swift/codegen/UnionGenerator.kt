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
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EnumDefinition
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.utils.CaseUtils

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
 *     case lion(Lion)
 *     case bear(Bear)
 *     case UNKNOWN(String)
 * }
 *
 * extension Attacker : Equatable, Codable {
 *     enum CodingKeys : String, CodingKey {
 *         case lion
 *         case bear
 *         case UNKNOWN
 *     }
 *
 *     func encode(to encoder: Encoder) throws {
 *         var container = encoder.container(keyedBy: CodingKeys.self)
 *         switch self {
 *         case let .lion(value):
 *         try container.encode(value, forKey: .lion)
 *         case let .bear(value):
 *         try container.encode(value, forKey: .bear)
 *         case let .UNKNOWN(value):
 *         try container.encode(value, forKey: .UNKNOWN)
 *         }
 *     }
 *
 *     init(from decoder: Decoder) throws {
 *         let container = try decoder.container(keyedBy: CodingKeys.self)
 *         if let value = try? container.decode(String.self, forKey: .lion) {
 *             self = .lion(value)
 *             return
 *         } else if let value = try? container.decode(Int.self, forKey: .bear) {
 *             self = .bear(value)
 *             return
 *         } else if let value = try? container.decode(Int.self, forKey: .UNKNOWN) {
 *             self = .UNKNOWN(value)
 *             return
 *         } else {
 *             self = .UNKNOWN("")
 *             return
 *         }
 *     }
 * }
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

    var codingKeysBuilder: MutableList<String> = mutableListOf<String>()
    var encodeBlockBuilder: MutableList<String> = mutableListOf<String>()
    var initFromDecoderBlockBuilder: MutableList<String> = mutableListOf<String>()

    fun render() {
        writer.writeShapeDocs(shape)
        writer.openBlock("enum ${unionSymbol.name} {", "}\n") {
            createUnionWriterContexts()
            // add the unknown case which will always be last
            writer.write("case UNKNOWN(String)")
        }

        writer.openBlock("extension ${unionSymbol.name} : Codable, Equatable { ", "}") {

            // Generate Coding Keys for serialization/deserialization
            generateCodingKeysEnumBlock()

            //Generate custom encoder
            generateEncodeBlock()

            // Generate custom decoder
            generateInitFromDecoderBlock()
        }
    }

    fun getEnumNameFromMemberShape(memberShape: MemberShape): String {
        return symbolProvider.toMemberName(memberShape)
    }

    fun getValueTypeFromMemberShape(memberShape: MemberShape): String {
        return symbolProvider.toSymbol(memberShape).name
    }

    fun addEnumCaseToEnum(memberShape: MemberShape) {
        writer.writeMemberDocs(model, memberShape)
        val enumName = getEnumNameFromMemberShape(memberShape = memberShape)
        val associatedValueType = getValueTypeFromMemberShape(memberShape = memberShape)
        writer.write("case $enumName($associatedValueType)")
    }

    fun addEnumCaseToCodingKeysEnum(memberShape: MemberShape) {
        val enumName = getEnumNameFromMemberShape(memberShape = memberShape)
        codingKeysBuilder.add("case $enumName")
    }

    fun addEnumCaseToEncodeBlock(memberShape: MemberShape) {
        val enumName = getEnumNameFromMemberShape(memberShape = memberShape)
        encodeBlockBuilder.add("case let .$enumName(value):\n    try container.encode(value, forKey: .$enumName)")
    }

    fun addEnumCaseToInitFromDecoderBlock(memberShape: MemberShape) {
        val enumName = getEnumNameFromMemberShape(memberShape = memberShape)
        initFromDecoderBlockBuilder.add(
                "if let value = try? container.decode(String.self, forKey: .$enumName) {\n" +
                "    self = .$enumName(value)\n" +
                "    return\n" +
                "}")
    }

    fun createUnionWriterContexts() {
        shape.getAllMembers().values.forEach {
            addEnumCaseToEnum(it)
            addEnumCaseToCodingKeysEnum(it)
            addEnumCaseToEncodeBlock(it)
            addEnumCaseToInitFromDecoderBlock(it)
        }
    }

    fun generateCodingKeysEnumBlock() {
        codingKeysBuilder.add("case UNKNOWN")
        writer.openBlock("enum CodingKeys: String, CodingKey {", "}") {
            writer.write(codingKeysBuilder.joinToString("\n"))
        }
    }

    fun generateEncodeBlock() {
        encodeBlockBuilder.add("case let .UNKNOWN(value):\n    try container.encode(value, forKey: .UNKNOWN)")
        writer.openBlock("func encode(to encoder: Encoder) throws {", "}") {
            writer.write("var container = encoder.container(keyedBy: CodingKeys.self)")
            writer.write("switch self {")
            writer.write(encodeBlockBuilder.joinToString("\n"))
            writer.write("}")
        }
    }

    fun generateInitFromDecoderBlock() {
        initFromDecoderBlockBuilder.add(
            "if let value = try? container.decode(String.self, forKey: .UNKNOWN) {\n" +
            "    self = .UNKNOWN(value)\n" +
            "    return\n" +
            "}")

        initFromDecoderBlockBuilder.add(
            "else {\n" +
            "    self = .UNKNOWN(\"\")\n" +
            "    return\n" +
            "}")

        writer.openBlock("init(from decoder: Decoder) throws {", "}") {
            writer.write("let container = try decoder.container(keyedBy: CodingKeys.self)")
            writer.write(initFromDecoderBlockBuilder.joinToString("\n"))
        }
    }
}
