/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

import io.kotest.matchers.string.*
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.*
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
    "k3": 3
]
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
    stringMember: "v1",
    boolMember: true,
    intMember: 1,
    structMember: Nested(
        tsMember: Date(timeIntervalSince1970: 11223344)
),
    enumMember: MyEnum(rawValue:"fooey")!,
    floatMember: 2,
    doubleMember: 3.0,
    nullMember: nil
)
""".trimIndent()

        contents.shouldContainOnlyOnce(expected)
    }
}
