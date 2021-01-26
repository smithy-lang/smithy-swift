/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.traits.EnumDefinition
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.swift.codegen.SwiftSettings.Companion.reservedKeywords
import software.amazon.smithy.utils.CaseUtils

/**
 * Generates an appropriate Swift type for a Smithy enum string.
 *
 * <p>For example, given the following Smithy model:
 *
 * ```
 * @enum([{ value: "YES", name: "YEP"},
 *        { value: "NO", name: "NOPE"}])
 * string TypedYesNo
 * ```
 * We will generate the following:
 * ```
 * enum TypedYesNo {
 *     case yep
 *     case nope
 *     case sdkUnknown(String)
 * }
 *
 *
 * extension TypedYesNo : Equatable, RawRepresentable, Codable, CaseIterable, Hashable {
 *     static var allCases: [TypedYesNo] {
 *         return [.yep, .nope, .sdkUnknown("")]
 *     }
 *
 *     init?(rawValue: String) {
 *         let value = Self.allCases.first(where: { $0.rawValue == rawValue })
 *         self = value ?? Self.sdkUnknown(rawValue)
 *     }
 *
 *     var rawValue: String {
 *         switch self {
 *         case .yep: return "YES"
 *         case .no: return "NO"
 *         case let .sdkUnknown(s): return s
 *         }
 *     }
 *
 *     init(from decoder: Decoder) throws {
 *         let container = try decoder.singleValueContainer()
 *         let rawValue = try container.decode(RawValue.self)
 *         self = TypedYesNo(rawValue: rawValue) ?? TypedYesNo.sdkUnknown(rawValue)
 *     }
 * }
 * ```
 *
 * Another Example, given the following Smithy model:
 *
 * ```
 * @enum([{ value: "YES" },
 *        { value: "NO" }])
 * string SimpleYesNo
 * ```
 * We will generate the following:
 * ```
 * enum SimpleYesNo {
 *     case yes
 *     case no
 *     case sdkUnknown(String)
 * }
 *
 *
 * extension SimpleYesNo : Equatable, RawRepresentable, Codable, CaseIterable, Hashable {
 *     static var allCases: [SimpleYesNo] {
 *         return [.yes, .no, .sdkUnknown("")]
 *     }
 *
 *     init?(rawValue: String) {
 *         let value = Self.allCases.first(where: { $0.rawValue == rawValue })
 *         self = value ?? Self.sdkUnknown(rawValue)
 *     }
 *
 *     var rawValue: String {
 *         switch self {
 *         case .yes: return "YES"
 *         case .no: return "NO"
 *         case let .sdkUnknown(s): return s
 *         }
 *     }
 *
 *     init(from decoder: Decoder) throws {
 *         let container = try decoder.singleValueContainer()
 *         let rawValue = try container.decode(RawValue.self)
 *         self = SimpleYesNo(rawValue: rawValue) ?? SimpleYesNo.sdkUnknown(rawValue)
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
        writer.openBlock("public enum \$enum.name:L {", "}\n") {
            createEnumWriterContexts()
            // add the sdkUnknown case which will always be last
            writer.write("case sdkUnknown(String)")
        }

        writer.openBlock("extension \$enum.name:L : Equatable, RawRepresentable, Codable, CaseIterable, Hashable { ", "}") {

            // Generate allCases static array
            generateAllCasesBlock()

            // Generate initializer from rawValue
            generateInitFromRawValueBlock()

            // Generate rawValue internal enum
            generateRawValueEnumBlock()

            // Generate deserializer
            generateInitFromDecoderBlock()
        }
        writer.removeContext("enum.name")
    }

    fun addEnumCaseToEnum(definition: EnumDefinition) {
        writer.writeEnumDefinitionDocs(definition)
        writer.write("case ${definition.swiftEnumCaseName()}")
    }

    fun addEnumCaseToAllCases(definition: EnumDefinition) {
        allCasesBuilder.add(".${definition.swiftEnumCaseName()}")
    }

    fun addEnumCaseToRawValuesEnum(definition: EnumDefinition) {
        rawValuesBuilder.add("case .${definition.swiftEnumCaseName()}: return \"${definition.value}\"")
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
        allCasesBuilder.add(".sdkUnknown(\"\")")
        writer.openBlock("public static var allCases: [\$enum.name:L] {", "}") {
            writer.openBlock("return [", "]") {
                writer.write(allCasesBuilder.joinToString(",\n"))
            }
        }
    }

    fun generateInitFromRawValueBlock() {
        writer.openBlock("public init?(rawValue: String) {", "}") {
            writer.write("let value = Self.allCases.first(where: { \$\$0.rawValue == rawValue })")
            writer.write("self = value ?? Self.sdkUnknown(rawValue)")
        }
    }

    fun generateRawValueEnumBlock() {
        rawValuesBuilder.add("case let .sdkUnknown(s): return s")
        writer.openBlock("public var rawValue: String {", "}") {
            writer.write("switch self {")
            writer.write(rawValuesBuilder.joinToString("\n"))
            writer.write("}")
        }
    }

    fun generateInitFromDecoderBlock() {
        writer.openBlock("public init(from decoder: Decoder) throws {", "}") {
            writer.write("let container = try decoder.singleValueContainer()")
            writer.write("let rawValue = try container.decode(RawValue.self)")
            writer.write("self = \$enum.name:L(rawValue: rawValue) ?? \$enum.name:L.sdkUnknown(rawValue)")
        }
    }

    /**
     * Creates an idiomatic name for swift enum cases from Smithy EnumDefinition.
     * Uses either name or value attributes of EnumDefinition in that order and formats
     * them to camelCase after removing chars except alphanumeric, space and underscore.
     */
    fun EnumDefinition.swiftEnumCaseName(): String {
        var enumCaseName = CaseUtils.toCamelCase(
            name.orElseGet {
                value
            }.replace(Regex("[^a-zA-Z0-9_ ]"), "")
        )
        if (!SymbolVisitor.isValidSwiftIdentifier(enumCaseName)) {
            enumCaseName = "_$enumCaseName"
        }

        if (reservedKeywords.contains(enumCaseName))
            enumCaseName = SymbolVisitor.escapeReservedWords(enumCaseName)

        return enumCaseName
    }
}
