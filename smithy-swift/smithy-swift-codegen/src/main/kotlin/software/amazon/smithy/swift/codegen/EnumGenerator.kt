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
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.traits.EnumDefinition
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.utils.CaseUtils

/**
 * Generates an appropriate Swift type for a Smithy enum string.
 *
 * <p>For example, given the following Smithy model:
 *
 * ```
 * @enum("YES": {name: "YEP"}, "NO": {name: "NOPE"})
 * string TypedYesNo
 * ```
 *
 * We will generate the following:
 *
 * ```
 * enum TypedYesNo {
 *     case yep
 *     case nope
 *     case unknown(String)
 * }
 *
 *
 * extension TypedYesNo : Equatable, RawRepresentable, Codable, CaseIterable {
 *     static var allCases: [TypedYesNo] {
 *         return [.yep, .nope, .unknown("")]
 *     }
 *
 *     init?(rawValue: String) {
 *         let value = Self.allCases.first(where: { $0.rawValue == rawValue })
 *         self = value ?? Self.unknown(rawValue)
 *     }
 *
 *     var rawValue: String {
 *         switch self {
 *         case .yep: return "YES"
 *         case .no: return "NO"
 *         case let .unknown(s): return s
 *         }
 *     }
 *
 *     init(from decoder: Decoder) throws {
 *         let container = try decoder.singleValueContainer()
 *         let rawValue = try container.decode(RawValue.self)
 *         self = TypedYesNo(rawValue: rawValue) ?? TypedYesNo.unknown(rawValue)
 *     }
 * }
 * ```
 *
 * Another Example, given the following Smithy model:
 *
 * ```
 * @enum("YES": {}, "NO": {})
 * string SimpleYesNo
 * ```
 *
 * We will generate the following:
 *
 * ```
 * enum SimpleYesNo {
 *     case yes
 *     case no
 *     case unknown(String)
 * }
 *
 *
 * extension SimpleYesNo : Equatable, RawRepresentable, Codable, CaseIterable {
 *     static var allCases: [SimpleYesNo] {
 *         return [.yes, .no, .unknown("")]
 *     }
 *
 *     init?(rawValue: String) {
 *         let value = Self.allCases.first(where: { $0.rawValue == rawValue })
 *         self = value ?? Self.unknown(rawValue)
 *     }
 *
 *     var rawValue: String {
 *         switch self {
 *         case .yes: return "YES"
 *         case .no: return "NO"
 *         case let .unknown(s): return s
 *         }
 *     }
 *
 *     init(from decoder: Decoder) throws {
 *         let container = try decoder.singleValueContainer()
 *         let rawValue = try container.decode(RawValue.self)
 *         self = SimpleYesNo(rawValue: rawValue) ?? SimpleYesNo.unknown(rawValue)
 *     }
 * }
 * ```
 */
class EnumGenerator(
    private val symbol: Symbol,
    private val writer: SwiftWriter,
    private val shape: StringShape
) {

    init {
        assert(shape.getTrait(EnumTrait::class.java).isPresent)
    }

    val enumTrait: EnumTrait by lazy {
        shape.getTrait(EnumTrait::class.java).get()
    }

    var allCasesBuilder: MutableList<String> = mutableListOf<String>()
    var rawValuesBuilder: MutableList<String> = mutableListOf<String>()

    fun render() {
        writer.putContext("enum.name", symbol.name)
        writer.writeShapeDocs(shape)
        writer.openBlock("enum \$enum.name:L {", "}\n") {
            createEnumWriterContexts()
            // add the unknown case which will always be last
            writer.write("case unknown(String)")
        }

        writer.openBlock("extension \$enum.name:L : Equatable, RawRepresentable, Codable, CaseIterable { ", "}") {

            // Generate allCases static array
            generateAllCasesBlock()

            // Generate initializer from rawValue
            generateInitFromRawValueBlock()

            // Generate rawValue internal enum
            generateRawValueEnumBlock()

            // Generate deserializer
            generateInitFromDecoderBlock()
        }
    }

    fun getEnumNameFromEnumDefinition(definition: EnumDefinition): String {
        return definition.name.orElseGet {
            CaseUtils.toSnakeCase(definition.value).replace(".", "_")
        }.toLowerCase()
    }

    fun addEnumCaseToEnum(definition: EnumDefinition) {
        writer.writeEnumDefinitionDocs(enumDefinition = definition)
        val enumName = getEnumNameFromEnumDefinition(definition = definition)
        writer.write("case $enumName")
    }

    fun addEnumCaseToAllCases(definition: EnumDefinition) {
        val enumName = getEnumNameFromEnumDefinition(definition = definition)
        allCasesBuilder.add(".$enumName")
    }

    fun addEnumCaseToRawValuesEnum(definition: EnumDefinition) {
        val enumName = getEnumNameFromEnumDefinition(definition = definition)
        rawValuesBuilder.add("case .$enumName: return \"${definition.value}\"")
    }

    fun createEnumWriterContexts() {
        enumTrait
            .values
            .sortedBy { it.name.orElse(it.value) }
            .forEach {
                // Add all given enum cases to generated enum definition
                addEnumCaseToEnum(it)
                addEnumCaseToAllCases(it)
                addEnumCaseToRawValuesEnum(it)
            }
    }

    fun generateAllCasesBlock() {
        allCasesBuilder.add(".unknown(\"\")")
        writer.openBlock("static var allCases: [\$enum.name:L] {", "}") {
            writer.openBlock("return [", "]") {
                writer.write(allCasesBuilder.joinToString(",\n"))
            }
        }
    }

    fun generateInitFromRawValueBlock() {
        writer.openBlock("init?(rawValue: String) {", "}") {
            writer.write("let value = Self.allCases.first(where: { \$\$0.rawValue == rawValue })")
            writer.write("self = value ?? Self.unknown(rawValue)")
        }
    }

    fun generateRawValueEnumBlock() {
        rawValuesBuilder.add("case let .unknown(s): return s")
        writer.openBlock("var rawValue: String {", "}") {
            writer.write("switch self {")
            writer.write(rawValuesBuilder.joinToString("\n"))
            writer.write("}")
        }
    }

    fun generateInitFromDecoderBlock() {
        writer.openBlock("init(from decoder: Decoder) throws {", "}") {
            writer.write("let container = try decoder.singleValueContainer()")
            writer.write("let rawValue = try container.decode(RawValue.self)")
            writer.write("self = \$enum.name:L(rawValue: rawValue) ?? \$enum.name:L.unknown(rawValue)")
        }
    }
}
