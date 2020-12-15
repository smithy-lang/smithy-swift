/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.DocumentationTrait
import software.amazon.smithy.model.traits.EnumDefinition
import software.amazon.smithy.model.traits.EnumTrait

class ShapeValueGeneratorTest {

    @Test
    fun `it renders maps`() {
        val keyMember = MemberShape.builder().id("foo.bar#MyMap\$key").target("smithy.api#String").build()
        val valueMember = MemberShape.builder().id("foo.bar#MyMap\$value").target("smithy.api#Integer").build()
        val map = MapShape.builder()
            .id("foo.bar#MyMap")
            .key(keyMember)
            .value(valueMember)
            .build()
        val model = Model.assembler()
            .addShapes(map, keyMember, valueMember)
            .assemble()
            .unwrap()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val mapShape = model.expectShape(ShapeId.from("foo.bar#MyMap"))
        val writer = SwiftWriter("test")

        val params = Node.objectNodeBuilder()
            .withMember("k1", 1)
            .withMember("k2", 2)
            .withMember("k3", 3)
            .build()

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, mapShape, params)
        val contents = writer.toString()
        val expected = """
[
    "k1": 1,
    "k2": 2,
    "k3": 3]
"""

        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders lists`() {
        val valueMember = MemberShape.builder().id("foo.bar#MyList\$member").target("smithy.api#String").build()
        val list = ListShape.builder()
            .id("foo.bar#MyList")
            .member(valueMember)
            .build()
        val model = Model.assembler()
            .addShapes(list, valueMember)
            .assemble()
            .unwrap()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val listShape = model.expectShape(ShapeId.from("foo.bar#MyList"))
        val writer = SwiftWriter("test")

        val values: Array<Node> = listOf("v1", "v2", "v3").map(Node::from).toTypedArray()
        val params = Node.arrayNode(*values)

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, listShape, params)
        val contents = writer.toString()

        val expected = """
[
    "v1",
    "v2",
    "v3"
]
""".trimIndent()

        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders sets`() {
        val valueMember = MemberShape.builder().id("foo.bar#MySet\$member").target("smithy.api#String").build()
        val set = SetShape.builder()
            .id("foo.bar#MySet")
            .member(valueMember)
            .build()
        val model = Model.assembler()
            .addShapes(set, valueMember)
            .assemble()
            .unwrap()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val setShape = model.expectShape(ShapeId.from("foo.bar#MySet"))
        val writer = SwiftWriter("test")

        val values: Array<Node> = listOf("v1", "v2", "v3").map(Node::from).toTypedArray()
        val params = Node.arrayNode(*values)

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, setShape, params)
        val contents = writer.toString()

        val expected = """
Set<String>(arrayLiteral: 
    "v1",
    "v2",
    "v3"
)
""".trimIndent()

        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders structs`() {
        val member1 = MemberShape.builder().id("foo.bar#MyStruct\$stringMember").target("smithy.api#String").build()
        val member2 = MemberShape.builder().id("foo.bar#MyStruct\$boolMember").target("smithy.api#Boolean").build()
        val member3 = MemberShape.builder().id("foo.bar#MyStruct\$intMember").target("smithy.api#Integer").build()

        val nestedMember1 = MemberShape.builder().id("foo.bar#Nested\$tsMember").target("smithy.api#Timestamp").build()
        val nested = StructureShape.builder()
            .id("foo.bar#Nested")
            .addMember(nestedMember1)
            .build()

        val member4 = MemberShape.builder().id("foo.bar#MyStruct\$structMember").target("foo.bar#Nested").build()

        val enumTrait = EnumTrait.builder()
            .addEnum(EnumDefinition.builder().value("fooey").name("FOO").build())
            .build()

        val enumShape = StringShape.builder()
            .id("foo.bar#MyEnum")
            .addTrait(enumTrait)
            .build()
        val member5 = MemberShape.builder().id("foo.bar#MyStruct\$enumMember").target("foo.bar#MyEnum").build()

        val member6 = MemberShape.builder().id("foo.bar#MyStruct\$floatMember").target("smithy.api#Float").build()
        val member7 = MemberShape.builder().id("foo.bar#MyStruct\$doubleMember").target("smithy.api#Double").build()

        val member8 = MemberShape.builder().id("foo.bar#MyStruct\$nullMember").target("smithy.api#String").build()

        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member1)
            .addMember(member2)
            .addMember(member3)
            .addMember(member4)
            .addMember(member5)
            .addMember(member6)
            .addMember(member7)
            .addMember(member8)
            .build()
        val model = Model.assembler()
            .addShapes(struct, member1, member2, member3)
            .addShapes(member4, nested, nestedMember1)
            .addShapes(member5, enumShape)
            .addShapes(member6, member7, member8)
            .assemble()
            .unwrap()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")

        val structShape = model.expectShape(ShapeId.from("foo.bar#MyStruct"))
        val writer = SwiftWriter("test")

        val params = Node.objectNodeBuilder()
            .withMember("stringMember", "v1")
            .withMember("boolMember", true)
            .withMember("intMember", 1)
            .withMember("structMember", Node.objectNodeBuilder()
                .withMember("tsMember", 11223344)
                .build()
            )
            .withMember("enumMember", "fooey")
            .withMember("floatMember", 2)
            .withMember("doubleMember", 3.0)
            .withMember("nullMember", Node.nullNode())
            .build()

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, structShape, params)
        val contents = writer.toString()

        val expected = """
MyStruct(
    boolMember: true,
    doubleMember: 3.0,
    enumMember: MyEnum(rawValue: "fooey")!,
    floatMember: 2,
    intMember: 1,
    nullMember: nil,
    stringMember: "v1",
    structMember: Nested(
        tsMember: Date(timeIntervalSince1970: 11223344)
    )
)
""".trimIndent()

        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders maps with null member`() {
        val keyMember = MemberShape.builder().id("foo.bar#MyMap\$key").target("smithy.api#String").build()
        val structMember = MemberShape.builder().id("foo.bar#MyStruct\$stringMember").target("smithy.api#String").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(structMember)
            .build()
        val valueMember = MemberShape.builder().id("foo.bar#MyMap\$value").target("foo.bar#MyStruct").build()
        val map = MapShape.builder()
            .id("foo.bar#MyMap")
            .key(keyMember)
            .value(valueMember)
            .build()
        val model = Model.assembler()
            .addShapes(map, keyMember, valueMember, struct, structMember)
            .assemble()
            .unwrap()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val mapShape = model.expectShape(ShapeId.from("foo.bar#MyMap"))
        val writer = SwiftWriter("test")

        val params = Node.objectNodeBuilder()
            .withMember("k1", Node.nullNode())
            .withMember("k2", Node.objectNodeBuilder()
                .withMember("stringMember", "hi")
                .build())
            .build()

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, mapShape, params)
        val contents = writer.toString()
        val expected =
            """
            [
                "k1": nil,
                "k2": MyStruct(
                    stringMember: "hi"
                )]
            """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders recursive member`() {

        val shapes = mutableListOf<StructureShape>()
        val memberFoo = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested1\$foo").target("smithy.api#String").build()
        var memberNested = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested1\$nested")
                .target("smithy.example#RecursiveShapesInputOutputNested2").build()

        val recursiveShapeNested1 = StructureShape.builder()
            .id("smithy.example#RecursiveShapesInputOutputNested1")
            .addMember(memberFoo)
            .addMember(memberNested)
            .build()
        val memberRecursiveMember = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested2\$recursiveMember").target("smithy.example#RecursiveShapesInputOutputNested1").build()
        val memberBar = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested2\$bar").target("smithy.api#String").build()

        val recursiveShapeNested2 = StructureShape.builder()
            .id("smithy.example#RecursiveShapesInputOutputNested2")
            .addMember(memberRecursiveMember)
            .addMember(memberBar)
            .build()

        val member1 = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutput\$nested").target("smithy.example#RecursiveShapesInputOutputNested1").build()

        val topLevelShape = StructureShape.builder()
            .id("smithy.example#RecursiveShapesInputOutput")
            .addMember(member1)
            .addTrait(DocumentationTrait("This *is* documentation about the shape."))
            .build()
        shapes.add(recursiveShapeNested1)
        shapes.add(recursiveShapeNested2)
        shapes.add(topLevelShape)

        var model = Model.assembler()
            .addShapes(recursiveShapeNested1, recursiveShapeNested2, topLevelShape)
            .addShapes(memberFoo, memberNested, memberRecursiveMember, memberBar, member1)
            .assemble()
            .unwrap()

        model = RecursiveShapeBoxer.transform(model) // Transform the model for recursive boxing change

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")

        /* 1. Test the RecursiveShapesInputOutputNested1 Struct:
            structure RecursiveShapesInputOutputNested1 {
                foo: String,
                nested: RecursiveShapesInputOutputNested2
            }
        * */
        var structShape = model.expectShape(ShapeId.from("smithy.example#RecursiveShapesInputOutputNested1"))
        var writer = SwiftWriter("test")
        var params = Node.objectNodeBuilder()
            .withMember("foo", "Foo1")
            .withMember("nested", Node.objectNodeBuilder()
                .withMember("bar", "Bar1")
                .build()
            )
            .build()

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, structShape, params)
        var contents = writer.toString()

        var expected = """
        RecursiveShapesInputOutputNested1(
            foo: "Foo1",
            nested: Box<RecursiveShapesInputOutputNested2>(
                value: RecursiveShapesInputOutputNested2(
                    bar: "Bar1"
                )
            )
        )
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)

        /* 2. Test the RecursiveShapesInputOutputNested2 Struct:
            structure RecursiveShapesInputOutputNested2 {
                bar: String,
                recursiveMember: RecursiveShapesInputOutputNested1
            }
        * */
        structShape = model.expectShape(ShapeId.from("smithy.example#RecursiveShapesInputOutputNested2"))
        writer = SwiftWriter("test")
        params = Node.objectNodeBuilder()
            .withMember("bar", "Bar1")
            .withMember("recursiveMember", Node.objectNodeBuilder()
                .withMember("foo", "Foo1")
                .build()
            )
            .build()

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, structShape, params)
        contents = writer.toString()

        expected = """
        RecursiveShapesInputOutputNested2(
            bar: "Bar1",
            recursiveMember: RecursiveShapesInputOutputNested1(
                foo: "Foo1"
            )
        )
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)

        /* 3. Test the RecursiveShapesInputOutput Struct:
            structure RecursiveShapesInputOutput {
                nested: RecursiveShapesInputOutputNested1
            }
        * */
        structShape = model.expectShape(ShapeId.from("smithy.example#RecursiveShapesInputOutput"))
        writer = SwiftWriter("test")
        params = Node.objectNodeBuilder()
            .withMember("nested", Node.objectNodeBuilder()
                .withMember("foo", "Foo1")
                .build()
            )
            .build()

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, structShape, params)
        contents = writer.toString()

        expected = """
        RecursiveShapesInputOutput(
            nested: RecursiveShapesInputOutputNested1(
                foo: "Foo1"
            )
        )
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders struct with BigInteger and BigDecimal`() {
        val member1 = MemberShape.builder().id("foo.bar#MyStruct\$bigDecimalMember").target("smithy.api#BigDecimal").build()
        val member2 = MemberShape.builder().id("foo.bar#MyStruct\$bigIntMember").target("smithy.api#BigInteger").build()
        val member3 = MemberShape.builder().id("foo.bar#MyStruct\$bigIntMemberNegative").target("smithy.api#BigInteger").build()

        val struct = StructureShape.builder()
                .id("foo.bar#MyStruct")
                .addMember(member1)
                .addMember(member2)
                .addMember(member3)
                .build()
        val model = Model.assembler()
                .addShapes(struct, member1, member2, member3)
                .assemble()
                .unwrap()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")

        val structShape = model.expectShape(ShapeId.from("foo.bar#MyStruct"))
        val writer = SwiftWriter("test")

        val params = Node.objectNodeBuilder()
                .withMember("bigDecimalMember", 25613525352378.523)
                .withMember("bigIntMember", 31825352653626)
                .withMember("bigIntMemberNegative", -31825352653626)
                .build()

        ShapeValueGenerator(model, provider).writeShapeValueInline(writer, structShape, params)
        val contents = writer.toString()

        val expected = """
import ComplexModule

MyStruct(
    bigDecimalMember: Complex(25613525352378.523),
    bigIntMember: Array(String(31825352653626).utf8),
    bigIntMemberNegative: Array(String(-31825352653626).utf8)
)
""".trimIndent()

        contents.shouldContainOnlyOnce(expected)
    }
}
