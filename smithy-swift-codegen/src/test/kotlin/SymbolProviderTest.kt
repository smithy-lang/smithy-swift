/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SymbolVisitor
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.isBoxed

class SymbolProviderTest {
    @Test fun `escapes reserved member names`() {
        val member = MemberShape.builder().id("foo.bar#MyStruct\$class").target("smithy.api#String").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member)
            .build()
        val model = createModelFromShapes(struct, member)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val actual = provider.toMemberName(member)
        assertEquals("`class`", actual)
    }

    @DisplayName("Creates primitives")
    @ParameterizedTest(name = "{index} ==> ''{0}''")
    @CsvSource(
        "String, String, nil, true, Swift",
        "Integer, Int, nil, true, Swift",
        "PrimitiveInteger, Int, 0, false, Swift",
        "Short, Int16, nil, true, Swift",
        "PrimitiveShort, Int16, 0, false, Swift",
        "Long, Int, nil, true, Swift",
        "PrimitiveLong, Int, 0, false, Swift",
        "Byte, Int8, nil, true, Swift",
        "PrimitiveByte, Int8, 0, false, Swift",
        "Float, Float, nil, true, Swift",
        "PrimitiveFloat, Float, 0.0, false, Swift",
        "Double, Double, nil, true, Swift",
        "PrimitiveDouble, Double, 0.0, false, Swift",
        "Boolean, Bool, nil, true, Swift",
        "PrimitiveBoolean, Bool, false, false, Swift",
        "Document, Document, nil, true, ClientRuntime"
    )
    fun `creates primitives`(primitiveType: String, swiftType: String, expectedDefault: String, boxed: Boolean, namespace: String?) {
        val model = """
            namespace foo.bar
            structure MyStruct {
                quux: $primitiveType
            }
       """.asSmithyModel()
        val member = model.expectShape(ShapeId.from("foo.bar#MyStruct\$quux"))
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val memberSymbol = provider.toSymbol(member)

        assertEquals(namespace ?: "", memberSymbol.namespace)
        assertEquals(expectedDefault, memberSymbol.defaultValue())
        assertEquals(boxed, memberSymbol.isBoxed())

        assertEquals(swiftType, memberSymbol.name)
    }

    @Test
    fun `can read box trait from member`() {
        val model = """
        namespace com.test
        structure MyStruct {
           @box
           foo: MyFoo
        }
        long MyFoo
        """.asSmithyModel()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val member = model.expectShape<MemberShape>("com.test#MyStruct\$foo")
        val memberSymbol = provider.toSymbol(member)
        assertEquals("Swift", memberSymbol.namespace)
        assertTrue(memberSymbol.isBoxed())
    }

    @Test
    fun `can read box trait from target`() {
        val model = """
        namespace com.test
        structure MyStruct {
           foo: MyFoo
        }
        @box
        long MyFoo
        """.asSmithyModel()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val member = model.expectShape<MemberShape>("com.test#MyStruct\$foo")
        val memberSymbol = provider.toSymbol(member)
        assertEquals("Swift", memberSymbol.namespace)
        assertTrue(memberSymbol.isBoxed())
    }

    @Test fun `creates blobs`() {
        val member = MemberShape.builder().id("foo.bar#MyStruct\$quux").target("smithy.api#Blob").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member)
            .build()
        val model = createModelFromShapes(struct, member)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val memberSymbol = provider.toSymbol(member)

        assertEquals("ClientRuntime", memberSymbol.namespace)
        assertEquals("nil", memberSymbol.defaultValue())
        assertEquals(true, memberSymbol.isBoxed())

        assertEquals("Data", memberSymbol.name)
    }

    @Test fun `creates dates`() {
        val member = MemberShape.builder().id("foo.bar#MyStruct\$quux").target("smithy.api#Timestamp").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member)
            .build()
        val model = createModelFromShapes(struct, member)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val memberSymbol = provider.toSymbol(member)

        assertEquals("ClientRuntime", memberSymbol.namespace)
        assertEquals("nil", memberSymbol.defaultValue())
        assertEquals(true, memberSymbol.isBoxed())

        assertEquals("Date", memberSymbol.name)
    }

    @Test fun `creates big ints`() {
        val member = MemberShape.builder().id("foo.bar#MyStruct\$quux").target("smithy.api#BigInteger").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member)
            .build()
        val model = createModelFromShapes(struct, member)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val memberSymbol = provider.toSymbol(member)

        assertEquals("ComplexModule", memberSymbol.namespace)
        assertEquals(true, memberSymbol.isBoxed())
        assertEquals("[UInt8]", memberSymbol.name)
    }

    @Test fun `creates lists`() {
        val struct = StructureShape.builder().id("foo.bar#Record").build()
        val listMember = MemberShape.builder().id("foo.bar#Records\$member").target(struct).build()
        val list = ListShape.builder()
            .id("foo.bar#Records")
            .member(listMember)
            .build()
        val model = createModelFromShapes(struct, list, listMember)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val listSymbol = provider.toSymbol(list)

        assertEquals("[Record]", listSymbol.name)
        assertEquals(true, listSymbol.isBoxed())
        assertEquals("nil", listSymbol.defaultValue())
    }

    @Test fun `creates sets`() {
        val struct = StructureShape.builder().id("foo.bar#Record").build()
        val setMember = MemberShape.builder().id("foo.bar#Records\$member").target(struct).build()
        val set = SetShape.builder()
            .id("foo.bar#Records")
            .member(setMember)
            .build()
        val model = createModelFromShapes(struct, set, setMember)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val setSymbol = provider.toSymbol(set)

        assertEquals("Set<Record>", setSymbol.name)
        assertEquals("Swift", setSymbol.namespace)
        assertEquals(true, setSymbol.isBoxed())
        assertEquals("nil", setSymbol.defaultValue())
    }

    @Test fun `creates maps`() {
        val struct = StructureShape.builder().id("foo.bar#Record").build()
        val keyMember = MemberShape.builder().id("foo.bar#MyMap\$key").target("smithy.api#String").build()
        val valueMember = MemberShape.builder().id("foo.bar#MyMap\$value").target(struct).build()
        val map = MapShape.builder()
            .id("foo.bar#MyMap")
            .key(keyMember)
            .value(valueMember)
            .build()
        val model = createModelFromShapes(struct, map, keyMember, valueMember)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val mapSymbol = provider.toSymbol(map)

        assertEquals("[Swift.String:Record]", mapSymbol.name)
        assertEquals(true, mapSymbol.isBoxed())
        assertEquals("nil", mapSymbol.defaultValue())
    }

    @Test
    fun `it handles recursive structures`() {
        /*
            structure MyStruct1{
                quux: String,
                nestedMember: MyStruct2
            }

            structure MyStruct2 {
                bar: String,
                recursiveMember: MyStruct1
            }
        */
        val memberQuux = MemberShape.builder().id("foo.bar#MyStruct1\$quux").target("smithy.api#String").build()
        val nestedMember = MemberShape.builder().id("foo.bar#MyStruct1\$nestedMember").target("foo.bar#MyStruct2").build()
        val struct1 = StructureShape.builder()
            .id("foo.bar#MyStruct1")
            .addMember(memberQuux)
            .addMember(nestedMember)
            .build()

        val memberBar = MemberShape.builder().id("foo.bar#MyStruct2\$bar").target("smithy.api#String").build()
        val recursiveMember = MemberShape.builder().id("foo.bar#MyStruct2\$recursiveMember").target("foo.bar#MyStruct1").build()
        val struct2 = StructureShape.builder()
            .id("foo.bar#MyStruct2")
            .addMember(memberBar)
            .addMember(recursiveMember)
            .build()
        val model = Model.assembler()
            .addShapes(struct1, memberQuux, nestedMember, struct2, memberBar, recursiveMember)
            .assemble()
            .unwrap()

        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, model.defaultSettings())
        val structSymbol = provider.toSymbol(struct1)
        assertEquals("MyStruct1", structSymbol.name)
        assertEquals(true, structSymbol.isBoxed())
        assertEquals("nil", structSymbol.defaultValue())
        assertEquals(2, structSymbol.references.size)
    }

    @Test
    fun `test checking valid swift name`() {
        val validNames = mutableListOf<String>("a", "a1", "_a", "_1")
        val invalidNames = mutableListOf<String>("0", "0.0", "a@")

        for (validName in validNames) {
            val isSwiftIdentifierValid = SymbolVisitor.isValidSwiftIdentifier(validName)
            assertTrue(isSwiftIdentifierValid, "$validName is wrongly interpreted as invalid swift identifier")
        }

        for (invalidName in invalidNames) {
            val isSwiftIdentifierValid = SymbolVisitor.isValidSwiftIdentifier(invalidName)
            assertFalse(isSwiftIdentifierValid, "$invalidName is wrongly interpreted as valid swift identifier")
        }
    }

    @Test
    fun `it adds namespace to nested structure`() {
        val memberQuux = MemberShape.builder()
            .id("foo.bar#Struct1\$quux")
            .target("smithy.api#String")
            .build()
        val struct1 = StructureShape.builder()
            .id("foo.bar#Struct1")
            .addMember(memberQuux)
            .build()
        val struct1AsMember = MemberShape.builder()
            .id("foo.bar#InputStruct\$foo")
            .target(struct1)
            .build()
        val input = StructureShape.builder()
            .id("foo.bar#InputStruct")
            .addMember(struct1AsMember)
            .build()
        val operation = OperationShape.builder()
            .id("foo.bar#TestOperation")
            .input(input)
            .build()
        val service = ServiceShape.builder()
            .id("foo.bar#QuuxService")
            .version("1.0")
            .addOperation(operation)
            .build()
        val model = Model.assembler()
            .addShapes(struct1, memberQuux, struct1AsMember, input, operation, service)
            .assemble()
            .unwrap()

        val updatedModel = NestedShapeTransformer.transform(model, service)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(updatedModel, updatedModel.defaultSettings(service.id.toString(), sdkId = "Quux"))
        val updatedStruct = updatedModel.expectShape(struct1.id)
        val updatedStructSymbol = provider.toSymbol(updatedStruct)

        assertEquals("QuuxClientTypes", updatedStructSymbol.namespace)
    }

    @Test
    fun `it does not add namespace to error structure`() {
        val memberQuux = MemberShape.builder()
            .id("foo.bar#ErrorStruct\$quux")
            .target("smithy.api#String")
            .build()
        val struct1Error = StructureShape.builder()
            .id("foo.bar#ErrorStruct")
            .addMember(memberQuux)
            .addTrait(ErrorTrait("client"))
            .build()
        val struct1AsMember = MemberShape.builder()
            .id("foo.bar#InputStruct\$foo")
            .target(struct1Error)
            .build()
        val input = StructureShape.builder()
            .id("foo.bar#InputStruct")
            .addMember(struct1AsMember)
            .build()
        val operation = OperationShape.builder()
            .id("foo.bar#TestOperation")
            .input(input)
            .build()
        val service = ServiceShape.builder()
            .id("foo.bar#QuuxService")
            .version("1.0")
            .addOperation(operation)
            .build()
        val model = Model.assembler()
            .addShapes(struct1Error, memberQuux, struct1AsMember, input, operation, service)
            .assemble()
            .unwrap()

        val updatedModel = NestedShapeTransformer.transform(model, service)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(updatedModel, updatedModel.defaultSettings(service.id.toString(), sdkId = "Quux"))
        val updatedStruct = updatedModel.expectShape(struct1Error.id)
        val updatedStructSymbol = provider.toSymbol(updatedStruct)

        assertEquals("", updatedStructSymbol.namespace)
    }
}
