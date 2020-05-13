package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.traits.EnumDefinition
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.utils.CaseUtils
import software.amazon.smithy.utils.StringUtils

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
 *     case YEP,
 *     case NOPE,
 *     case UNKNOWN(String)
 * }
 *
 *
 * extension TypedYesNo : Equatable, RawRepresentable, Codable, CaseIterable {
 *     static var allCases: [TypedYesNo] {
 *         return [.YEP, .NOPE, .UNKNOWN("")]
 *     }
 *
 *     init?(rawValue: String) {
 *         let value = Self.allCases.first(where: { $0.rawValue == rawValue })
 *         self = value ?? Self.UNKNOWN(rawValue)
 *     }
 *
 *     var rawValue: String {
 *         switch self {
 *         case .YEP: return "YES"
 *         case .NOPE: return "NOPE"
 *         case let .UNKNOWN(s): return s
 *         }
 *     }
 *
 *     init(from decoder: Decoder) throws {
 *         let container = try decoder.singleValueContainer()
 *         let rawValue = try container.decode(RawValue.self)
 *         self = TypedYesNo(rawValue: rawValue) ?? TypedYesNo.UNKNOWN(rawValue)
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
 *     case YES,
 *     case NO,
 *     case UNKNOWN(String)
 * }
 *
 *
 * extension SimpleYesNo : Equatable, RawRepresentable, Codable, CaseIterable {
 *     static var allCases: [SimpleYesNo] {
 *         return [.YES, .NO, .UNKNOWN("")]
 *     }
 *
 *     init?(rawValue: String) {
 *         let value = Self.allCases.first(where: { $0.rawValue == rawValue })
 *         self = value ?? Self.UNKNOWN(rawValue)
 *     }
 *
 *     var rawValue: String {
 *         switch self {
 *         case .YES: return "YES"
 *         case .NO: return "NO"
 *         case let .UNKNOWN(s): return s
 *         }
 *     }
 *
 *     init(from decoder: Decoder) throws {
 *         let container = try decoder.singleValueContainer()
 *         let rawValue = try container.decode(RawValue.self)
 *         self = SimpleYesNo(rawValue: rawValue) ?? SimpleYesNo.UNKNOWN(rawValue)
 *     }
 * }
 * ```
 */
class EnumGenerator(
    private val model: Model,
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: StringShape
) {

    init {
        assert(shape.getTrait(EnumTrait::class.java).isPresent)
    }

    val enumTrait: EnumTrait by lazy {
        shape.getTrait(EnumTrait::class.java).get()
    }

    val enumSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    var allCasesBuilder: MutableList<String> = mutableListOf<String>()
    var rawValuesBuilder: MutableList<String> = mutableListOf<String>()

    fun render() {
        writer.writeShapeDocs(shape)
        writer.openBlock("enum ${enumSymbol.name} {", "}\n") {
            createEnumWriterContexts()
            // add the unknown case which will always be last
            writer.write("case UNKNOWN(String)")
        }

        writer.openBlock("extension ${enumSymbol.name} : Equatable, RawRepresentable, Codable, CaseIterable { ", "}") {

            // Generate allCases static array
            generateAllCasesBlock()

            //Generate initializer from rawValue
            generateInitFromRawValueBlock()

            // Generate rawValue internal enum
            generateRawValueEnumBlock()

            //Generate deserializer
            generateInitFromDecoderBlock()
        }
    }

    fun getEnumNameFromEnumDefinition(definition: EnumDefinition): String {
        return definition.name.orElseGet {
            CaseUtils.toSnakeCase(definition.value).replace(".", "_")
        }.toUpperCase()
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
        allCasesBuilder.add(".UNKNOWN(\"\")")
        writer.openBlock("static var allCases: [${enumSymbol.name}] {", "}") {
            writer.openBlock("return [", "]") {
                writer.write(allCasesBuilder.joinToString(",\n"))
            }
        }
    }

    fun generateInitFromRawValueBlock() {
        writer.openBlock("init?(rawValue: String) {", "}") {
            writer.write("let value = Self.allCases.first(where: { \$\$0.rawValue == rawValue })")
            writer.write("self = value ?? Self.UNKNOWN(rawValue)")
        }
    }

    fun generateRawValueEnumBlock() {
        rawValuesBuilder.add("case let .UNKNOWN(s): return s")
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
            writer.write("self = ${enumSymbol.name}(rawValue: rawValue) ?? ${enumSymbol.name}.UNKNOWN(rawValue)")
        }
    }
}
