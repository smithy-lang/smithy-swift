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

        val expectedGeneratedEnum =
            """
/**
 Really long multi-line
 Documentation for MyUnion
 */
public enum MyUnion {
    case foo(String)
    case baz(Int)
    /// Documentation for bar
    case bar(Int)
    case sdkUnknown(String)
}

extension MyUnion : Codable {
    enum CodingKeys: String, CodingKey {
        case foo
        case baz
        case bar
        case sdkUnknown
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .foo(value):
            try container.encode(value, forKey: .foo)
        case let .baz(value):
            try container.encode(value, forKey: .baz)
        case let .bar(value):
            try container.encode(value, forKey: .bar)
        case let .sdkUnknown(value):
            try container.encode(value, forKey: .sdkUnknown)
        }
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .foo) {
            self = .foo(value)
            return
        }
        if let value = try? container.decode(Int.self, forKey: .baz) {
            self = .baz(value)
            return
        }
        if let value = try? container.decode(Int.self, forKey: .bar) {
            self = .bar(value)
            return
        }
        else {
            self = .sdkUnknown("")
            return
        }
    }
}
            """.trimIndent()


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

        val expectedGeneratedEnum =
            """
/**
 Really long multi-line
 Documentation for MyUnion
 */
public enum MyUnion {
    case foo(String)
    /// Documentation for bar
    case bar(Int)
    case myStruct(MyStruct)
    case sdkUnknown(String)
}

extension MyUnion : Codable {
    enum CodingKeys: String, CodingKey {
        case foo
        case bar
        case myStruct
        case sdkUnknown
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .foo(value):
            try container.encode(value, forKey: .foo)
        case let .bar(value):
            try container.encode(value, forKey: .bar)
        case let .myStruct(value):
            try container.encode(value, forKey: .myStruct)
        case let .sdkUnknown(value):
            try container.encode(value, forKey: .sdkUnknown)
        }
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .foo) {
            self = .foo(value)
            return
        }
        if let value = try? container.decode(Int.self, forKey: .bar) {
            self = .bar(value)
            return
        }
        if let value = try? container.decode(MyStruct.self, forKey: .myStruct) {
            self = .myStruct(value)
            return
        }
        else {
            self = .sdkUnknown("")
            return
        }
    }
}
            """.trimIndent()

        contents.shouldContain(expectedGeneratedEnum)
    }

    private fun createUnionShapeBuilderWithMembers(vararg memberShapes: MemberShape): UnionShape.Builder {
        val unionShapeBuilder = UnionShape.builder()
        unionShapeBuilder.id("smithy.example#MyUnion").addTrait(DocumentationTrait("Really long multi-line\n" +
                "Documentation for MyUnion"))
        for (memberShape in memberShapes) {
            unionShapeBuilder.addMember(memberShape)
        }
        return unionShapeBuilder
    }
}
