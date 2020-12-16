/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.traits.DocumentationTrait
import software.amazon.smithy.model.traits.EnumDefinition
import software.amazon.smithy.model.traits.EnumTrait

class EnumGeneratorTests : TestsBase() {

    @Test
    fun `generates unnamed enums`() {

        val stringShapeWithEnumTrait = createStringWithEnumTrait(
            EnumDefinition.builder().value("FOO_BAZ@-. XAP - . ").build(),
            EnumDefinition.builder().value("BAR").documentation("Documentation for BAR").build()
        )
        val model = createModelFromShapes(stringShapeWithEnumTrait)

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")

        val generator = EnumGenerator(provider.toSymbol(stringShapeWithEnumTrait), writer, stringShapeWithEnumTrait)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum = "" +
                "/**\n" +
                " Really long multi-line\n" +
                " Documentation for the enum\n" +
                " */\n" +
                "public enum MyEnum {\n" +
                "    /// Documentation for BAR\n" +
                "    case bar\n" +
                "    case fooBazXap\n" +
                "    case sdkUnknown(String)\n" +
                "}\n" +
                "\n" +
                "extension MyEnum : Equatable, RawRepresentable, Codable, CaseIterable, Hashable {\n" +
                "    public static var allCases: [MyEnum] {\n" +
                "        return [\n" +
                "            .bar,\n" +
                "            .fooBazXap,\n" +
                "            .sdkUnknown(\"\")\n" +
                "        ]\n" +
                "    }\n" +
                "    public init?(rawValue: String) {\n" +
                "        let value = Self.allCases.first(where: { \$0.rawValue == rawValue })\n" +
                "        self = value ?? Self.sdkUnknown(rawValue)\n" +
                "    }\n" +
                "    public var rawValue: String {\n" +
                "        switch self {\n" +
                "        case .bar: return \"BAR\"\n" +
                "        case .fooBazXap: return \"FOO_BAZ@-. XAP - . \"\n" +
                "        case let .sdkUnknown(s): return s\n" +
                "        }\n" +
                "    }\n" +
                "    public init(from decoder: Decoder) throws {\n" +
                "        let container = try decoder.singleValueContainer()\n" +
                "        let rawValue = try container.decode(RawValue.self)\n" +
                "        self = MyEnum(rawValue: rawValue) ?? MyEnum.sdkUnknown(rawValue)\n" +
                "    }\n" +
                "}"

        contents.shouldContain(expectedGeneratedEnum)
    }

    @Test
    fun `generates named enums`() {
        val stringShapeWithEnumTrait = createStringWithEnumTrait(
            EnumDefinition.builder().value("t2.nano").name("T2_NANO").build(),
            EnumDefinition.builder().value("t2.micro")
                                    .name("T2_MICRO")
                                    .documentation("\"\"\"\n" +
                                        "T2 instances are Burstable Performance\n" +
                                        "Instances that provide a baseline level of CPU\n" +
                                        "performance with the ability to burst above the\n" +
                                        "baseline.\"\"\"")
                                    .build()
        )
        val model = createModelFromShapes(stringShapeWithEnumTrait)

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")

        val generator = EnumGenerator(provider.toSymbol(stringShapeWithEnumTrait), writer, stringShapeWithEnumTrait)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum = "" +
                "/**\n" +
                " Really long multi-line\n" +
                " Documentation for the enum\n" +
                " */\n" +
                "public enum MyEnum {\n" +
                "    /**\n" +
                "     \"\"\"\n" +
                "     T2 instances are Burstable Performance\n" +
                "     Instances that provide a baseline level of CPU\n" +
                "     performance with the ability to burst above the\n" +
                "     baseline.\"\"\"\n" +
                "     */\n" +
                "    case t2Micro\n" +
                "    case t2Nano\n" +
                "    case sdkUnknown(String)\n" +
                "}\n" +
                "\n" +
                "extension MyEnum : Equatable, RawRepresentable, Codable, CaseIterable, Hashable {\n" +
                "    public static var allCases: [MyEnum] {\n" +
                "        return [\n" +
                "            .t2Micro,\n" +
                "            .t2Nano,\n" +
                "            .sdkUnknown(\"\")\n" +
                "        ]\n" +
                "    }\n" +
                "    public init?(rawValue: String) {\n" +
                "        let value = Self.allCases.first(where: { \$0.rawValue == rawValue })\n" +
                "        self = value ?? Self.sdkUnknown(rawValue)\n" +
                "    }\n" +
                "    public var rawValue: String {\n" +
                "        switch self {\n" +
                "        case .t2Micro: return \"t2.micro\"\n" +
                "        case .t2Nano: return \"t2.nano\"\n" +
                "        case let .sdkUnknown(s): return s\n" +
                "        }\n" +
                "    }\n" +
                "    public init(from decoder: Decoder) throws {\n" +
                "        let container = try decoder.singleValueContainer()\n" +
                "        let rawValue = try container.decode(RawValue.self)\n" +
                "        self = MyEnum(rawValue: rawValue) ?? MyEnum.sdkUnknown(rawValue)\n" +
                "    }\n" +
                "}"

        contents.shouldContain(expectedGeneratedEnum)
    }

    private fun createStringWithEnumTrait(vararg enumDefinitions: EnumDefinition): StringShape {
        val enumTraitBuilder = EnumTrait.builder()
        for (enumDefinition in enumDefinitions) {
            enumTraitBuilder.addEnum(enumDefinition)
        }

        val shape = StringShape.builder()
            .id("smithy.example#MyEnum")
            .addTrait(enumTraitBuilder.build())
            .addTrait(DocumentationTrait("Really long multi-line\nDocumentation for the enum"))
            .build()

        return shape
    }
}
