/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.DocumentationTrait
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.UnionGenerator
import software.amazon.smithy.swift.codegen.model.UnionIndirectivizer

class UnionGeneratorTests {

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
        val settings = model.defaultSettings()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings)
        val writer = SwiftWriter("MockPackage")

        val generator = UnionGenerator(model, provider, writer, simpleUnionShape, settings)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum =
            """
            /// Really long multi-line Documentation for MyUnion
            public enum MyUnion: Swift.Equatable {
                case foo(Swift.String)
                case baz(Swift.Int)
                /// Documentation for bar
                case bar(Swift.Int)
                case sdkUnknown(Swift.String)
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
        val settings = model.defaultSettings()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings)
        val writer = SwiftWriter("MockPackage")

        val generator = UnionGenerator(model, provider, writer, unionShapeWithStructMember, settings)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum =
            """
            /// Really long multi-line Documentation for MyUnion
            public enum MyUnion: Swift.Equatable {
                case foo(Swift.String)
                /// Documentation for bar
                case bar(Swift.Int)
                case mystruct(MyStruct)
                case sdkUnknown(Swift.String)
            }
            """.trimIndent()

        contents.shouldContain(expectedGeneratedEnum)
    }

    @Test
    fun `it renders recursive union shape`() {
        val simpleUnionShapeBuilder = createUnionShapeBuilderWithMembers(
            MemberShape.builder().id("smithy.example#MyUnion\$foo").target("smithy.example#MyUnion").build(),
            MemberShape.builder().id("smithy.example#MyUnion\$baz").target("smithy.api#Integer").build(),
            MemberShape.builder().id("smithy.example#MyUnion\$bar")
                .target("smithy.api#PrimitiveInteger")
                .addTrait(DocumentationTrait("Documentation for bar"))
                .build()
        )
        val simpleUnionShape = simpleUnionShapeBuilder.build()
        val model = createModelFromShapes(simpleUnionShape)
        val transformedModel = UnionIndirectivizer.transform(model)
        val settings = transformedModel.defaultSettings()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(transformedModel, settings)
        val writer = SwiftWriter("MockPackage")
        val transformedUnionShape = transformedModel.expectShape(simpleUnionShape.id).asUnionShape().get()

        val generator = UnionGenerator(transformedModel, provider, writer, transformedUnionShape, settings)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedEnum =
            """
            /// Really long multi-line Documentation for MyUnion
            public indirect enum MyUnion: Swift.Equatable {
                /// Really long multi-line Documentation for MyUnion
                case foo(MyUnion)
                case baz(Swift.Int)
                /// Documentation for bar
                case bar(Swift.Int)
                case sdkUnknown(Swift.String)
            }
            """.trimIndent()

        contents.shouldContain(expectedGeneratedEnum)
    }

    private fun createUnionShapeBuilderWithMembers(vararg memberShapes: MemberShape): UnionShape.Builder {
        val unionShapeBuilder = UnionShape.builder()
        unionShapeBuilder.id("smithy.example#MyUnion").addTrait(
            DocumentationTrait(
                "Really long multi-line\n" +
                    "Documentation for MyUnion"
            )
        )
        for (memberShape in memberShapes) {
            unionShapeBuilder.addMember(memberShape)
        }
        return unionShapeBuilder
    }
}
