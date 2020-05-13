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

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.DocumentationTrait

class UnionGeneratorTests : TestsBase() {

    @Test
    fun `it renders simple union shape`() {

        val simpleUnionShapeBuilder = createUnionShapeBuilderWithMembers(
            MemberShape.builder().id("smithy.example#MyUnion\$foo").target("smithy.api#String").build(),
            MemberShape.builder().id("smithy.example#MyUnion\$baz").target("smithy.api#Integer").build(),
            MemberShape.builder().id("smithy.example#MyUnion\$bar")
                .target("smithy.api#PrimitiveInteger")
                .addTrait(DocumentationTrait("Documentation for bar"))
                .build()
        )
        val simpleUnionShape = simpleUnionShapeBuilder.build()
        val model = createModelFromShapes(simpleUnionShape)

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")

        val generator = UnionGenerator(model, provider, writer, simpleUnionShape)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum = "" +
                "/**\n" +
                " * Documentation for MyUnion\n" +
                " */\n" +
                "enum MyUnion {\n" +
                "    /**\n" +
                "     * Documentation for bar\n" +
                "     */\n" +
                "    case bar(Int)\n" +
                "    case baz(Int)\n" +
                "    case foo(String)\n" +
                "    case UNKNOWN(String)\n" +
                "}\n" +
                "\n" +
                "extension MyUnion : Codable, Equatable {\n" +
                "    enum CodingKeys: String, CodingKey {\n" +
                "        case bar\n" +
                "        case baz\n" +
                "        case foo\n" +
                "        case UNKNOWN\n" +
                "    }\n" +
                "    func encode(to encoder: Encoder) throws {\n" +
                "        var container = encoder.container(keyedBy: CodingKeys.self)\n" +
                "        switch self {\n" +
                "        case let .bar(value):\n" +
                "            try container.encode(value, forKey: .bar)\n" +
                "        case let .baz(value):\n" +
                "            try container.encode(value, forKey: .baz)\n" +
                "        case let .foo(value):\n" +
                "            try container.encode(value, forKey: .foo)\n" +
                "        case let .UNKNOWN(value):\n" +
                "            try container.encode(value, forKey: .UNKNOWN)\n" +
                "        }\n" +
                "    }\n" +
                "    init(from decoder: Decoder) throws {\n" +
                "        let container = try decoder.container(keyedBy: CodingKeys.self)\n" +
                "        if let value = try? container.decode(String.self, forKey: .bar) {\n" +
                "            self = .bar(value)\n" +
                "            return\n" +
                "        }\n" +
                "        if let value = try? container.decode(String.self, forKey: .baz) {\n" +
                "            self = .baz(value)\n" +
                "            return\n" +
                "        }\n" +
                "        if let value = try? container.decode(String.self, forKey: .foo) {\n" +
                "            self = .foo(value)\n" +
                "            return\n" +
                "        }\n" +
                "        if let value = try? container.decode(String.self, forKey: .UNKNOWN) {\n" +
                "            self = .UNKNOWN(value)\n" +
                "            return\n" +
                "        }\n" +
                "        else {\n" +
                "            self = .UNKNOWN(\"\")\n" +
                "            return\n" +
                "        }\n" +
                "    }\n" +
                "}\n"

        contents.shouldContain(expectedGeneratedEnum)
    }

    @Test
    fun `it renders union shape with struct member`() {

        val struct = StructureShape.builder()
            .id("smithy.example#MyStruct")
            .addMember(MemberShape.builder().id("smithy.example#MyStruct\$baz").target("smithy.api#String").build())
            .build()

        val unionShapeBuilder = createUnionShapeBuilderWithMembers(
            MemberShape.builder().id("smithy.example#MyUnion\$foo").target("smithy.api#String").build(),
            MemberShape.builder().id("smithy.example#MyUnion\$bar")
                .target("smithy.api#PrimitiveInteger")
                .addTrait(DocumentationTrait("Documentation for bar"))
                .build()
        )
        unionShapeBuilder.addMember("myStruct", struct.id)
        val unionShapeWithStructMember = unionShapeBuilder.build()
        val model = createModelFromShapes(struct, unionShapeWithStructMember)

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")

        val generator = UnionGenerator(model, provider, writer, unionShapeWithStructMember)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum = "" +
                "/**\n" +
                " * Documentation for MyUnion\n" +
                " */\n" +
                "enum MyUnion {\n" +
                "    /**\n" +
                "     * Documentation for bar\n" +
                "     */\n" +
                "    case bar(Int)\n" +
                "    case foo(String)\n" +
                "    case myStruct(MyStruct)\n" +
                "    case UNKNOWN(String)\n" +
                "}\n" +
                "\n" +
                "extension MyUnion : Codable, Equatable {\n" +
                "    enum CodingKeys: String, CodingKey {\n" +
                "        case bar\n" +
                "        case foo\n" +
                "        case myStruct\n" +
                "        case UNKNOWN\n" +
                "    }\n" +
                "    func encode(to encoder: Encoder) throws {\n" +
                "        var container = encoder.container(keyedBy: CodingKeys.self)\n" +
                "        switch self {\n" +
                "        case let .bar(value):\n" +
                "            try container.encode(value, forKey: .bar)\n" +
                "        case let .foo(value):\n" +
                "            try container.encode(value, forKey: .foo)\n" +
                "        case let .myStruct(value):\n" +
                "            try container.encode(value, forKey: .myStruct)\n" +
                "        case let .UNKNOWN(value):\n" +
                "            try container.encode(value, forKey: .UNKNOWN)\n" +
                "        }\n" +
                "    }\n" +
                "    init(from decoder: Decoder) throws {\n" +
                "        let container = try decoder.container(keyedBy: CodingKeys.self)\n" +
                "        if let value = try? container.decode(String.self, forKey: .bar) {\n" +
                "            self = .bar(value)\n" +
                "            return\n" +
                "        }\n" +
                "        if let value = try? container.decode(String.self, forKey: .foo) {\n" +
                "            self = .foo(value)\n" +
                "            return\n" +
                "        }\n" +
                "        if let value = try? container.decode(String.self, forKey: .myStruct) {\n" +
                "            self = .myStruct(value)\n" +
                "            return\n" +
                "        }\n" +
                "        if let value = try? container.decode(String.self, forKey: .UNKNOWN) {\n" +
                "            self = .UNKNOWN(value)\n" +
                "            return\n" +
                "        }\n" +
                "        else {\n" +
                "            self = .UNKNOWN(\"\")\n" +
                "            return\n" +
                "        }\n" +
                "    }\n" +
                "}\n"

        contents.shouldContain(expectedGeneratedEnum)
    }

    private fun createUnionShapeBuilderWithMembers(vararg memberShapes: MemberShape): UnionShape.Builder {
        val unionShapeBuilder = UnionShape.builder()
        unionShapeBuilder.id("smithy.example#MyUnion").addTrait(DocumentationTrait("Documentation for MyUnion"))
        for (memberShape in memberShapes) {
            unionShapeBuilder.addMember(memberShape)
        }
        return unionShapeBuilder
    }
}
