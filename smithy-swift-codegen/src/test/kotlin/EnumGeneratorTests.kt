/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.traits.DocumentationTrait
import software.amazon.smithy.model.traits.EnumDefinition
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.swift.codegen.EnumGenerator
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftWriter

class EnumGeneratorTests {

    @Test
    fun `generates unnamed enums`() {

        val stringShapeWithEnumTrait = createStringWithEnumTrait(
            EnumDefinition.builder().value("FOO_BAZ@-. XAP - . ").build(),
            EnumDefinition.builder().value("BAR").documentation("Documentation for BAR").build()
        )
        val model = createModelFromShapes(stringShapeWithEnumTrait)

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val writer = SwiftWriter("MockPackage")

        val generator = EnumGenerator(provider.toSymbol(stringShapeWithEnumTrait), writer, stringShapeWithEnumTrait)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum =
            """
            /// Really long multi-line
            /// Documentation for the enum
            public enum MyEnum {
                /// Documentation for BAR
                case bar
                case fooBazXap
                case sdkUnknown(Swift.String)
            }
            
            extension MyEnum : Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
                public static var allCases: [MyEnum] {
                    return [
                        .bar,
                        .fooBazXap,
                        .sdkUnknown("")
                    ]
                }
                public init?(rawValue: Swift.String) {
                    let value = Self.allCases.first(where: { ${'$'}0.rawValue == rawValue })
                    self = value ?? Self.sdkUnknown(rawValue)
                }
                public var rawValue: Swift.String {
                    switch self {
                    case .bar: return "BAR"
                    case .fooBazXap: return "FOO_BAZ@-. XAP - . "
                    case let .sdkUnknown(s): return s
                    }
                }
                public init(from decoder: Swift.Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(RawValue.self)
                    self = MyEnum(rawValue: rawValue) ?? MyEnum.sdkUnknown(rawValue)
                }
            }
            """.trimIndent()

        contents.shouldContain(expectedGeneratedEnum)
    }

    @Test
    fun `generates named enums`() {
        val stringShapeWithEnumTrait = createStringWithEnumTrait(
            EnumDefinition.builder().value("t2.nano").name("T2_NANO").build(),
            EnumDefinition.builder().value("t2.micro")
                .name("T2_MICRO")
                .documentation(
                    "\"\"\"\n" +
                        "T2 instances are Burstable Performance\n" +
                        "Instances that provide a baseline level of CPU\n" +
                        "performance with the ability to burst above the\n" +
                        "baseline.\"\"\""
                )
                .build()
        )
        val model = createModelFromShapes(stringShapeWithEnumTrait)

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val writer = SwiftWriter("MockPackage")

        val generator = EnumGenerator(provider.toSymbol(stringShapeWithEnumTrait), writer, stringShapeWithEnumTrait)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum =
            """
            /// Really long multi-line
            /// Documentation for the enum
            public enum MyEnum {
                /// ""${'"'}
                /// T2 instances are Burstable Performance
                /// Instances that provide a baseline level of CPU
                /// performance with the ability to burst above the
                /// baseline.""${'"'}
                case t2Micro
                case t2Nano
                case sdkUnknown(Swift.String)
            }
            
            extension MyEnum : Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
                public static var allCases: [MyEnum] {
                    return [
                        .t2Micro,
                        .t2Nano,
                        .sdkUnknown("")
                    ]
                }
                public init?(rawValue: Swift.String) {
                    let value = Self.allCases.first(where: { ${'$'}0.rawValue == rawValue })
                    self = value ?? Self.sdkUnknown(rawValue)
                }
                public var rawValue: Swift.String {
                    switch self {
                    case .t2Micro: return "t2.micro"
                    case .t2Nano: return "t2.nano"
                    case let .sdkUnknown(s): return s
                    }
                }
                public init(from decoder: Swift.Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(RawValue.self)
                    self = MyEnum(rawValue: rawValue) ?? MyEnum.sdkUnknown(rawValue)
                }
            }
            """.trimIndent()

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
