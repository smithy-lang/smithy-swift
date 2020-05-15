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

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.*

class SymbolProviderTest : TestsBase() {
    @Test fun `escapes reserved member names`() {
        val member = MemberShape.builder().id("foo.bar#MyStruct\$class").target("smithy.api#String").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member)
            .build()
        val model = createModelFromShapes(struct, member)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val actual = provider.toMemberName(member)
        assertEquals("`class`", actual)
    }

    @DisplayName("Creates primitives")
    @ParameterizedTest(name = "{index} ==> ''{0}''")
    @CsvSource(
        "String, String, nil, true,",
        "Integer, Int, nil, true,",
        "PrimitiveInteger, Int, 0, false,",
        "Short, Int16, nil, true,",
        "PrimitiveShort, Int16, 0, false,",
        "Long, Int, nil, true,",
        "PrimitiveLong, Int, 0, false,",
        "Byte, Int8, nil, true,",
        "PrimitiveByte, Int8, 0, false,",
        "Float, Float, nil, true,",
        "PrimitiveFloat, Float, 0.0, false,",
        "Double, Double, nil, true,",
        "PrimitiveDouble, Double, 0.0, false,",
        "Boolean, Bool, nil, true,",
        "PrimitiveBoolean, Bool, false, false,",
        "Document, JSONValue, nil, true, ClientRuntime"
    )
    fun `creates primitives`(primitiveType: String, swiftType: String, expectedDefault: String, boxed: Boolean, namespace: String?) {
        val member = MemberShape.builder().id("foo.bar#MyStruct\$quux").target("smithy.api#$primitiveType").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member)
            .build()
        val model = createModelFromShapes(struct, member)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val memberSymbol = provider.toSymbol(member)

        assertEquals(namespace ?: "", memberSymbol.namespace)
        assertEquals(expectedDefault, memberSymbol.defaultValue())
        assertEquals(boxed, memberSymbol.isBoxed())

        assertEquals(swiftType, memberSymbol.name)
    }

    @Test fun `creates blobs`() {
        val member = MemberShape.builder().id("foo.bar#MyStruct\$quux").target("smithy.api#Blob").build()
        val struct = StructureShape.builder()
            .id("foo.bar#MyStruct")
            .addMember(member)
            .build()
        val model = createModelFromShapes(struct, member)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val memberSymbol = provider.toSymbol(member)

        assertEquals("Foundation", memberSymbol.namespace)
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
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val memberSymbol = provider.toSymbol(member)

        assertEquals("Foundation", memberSymbol.namespace)
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
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val memberSymbol = provider.toSymbol(member)

        assertEquals("BigNumber", memberSymbol.namespace)
        assertEquals(true, memberSymbol.isBoxed())
        assertEquals("BInt", memberSymbol.name)
    }

    @Test fun `creates lists`() {
        val struct = StructureShape.builder().id("foo.bar#Record").build()
        val listMember = MemberShape.builder().id("foo.bar#Records\$member").target(struct).build()
        val list = ListShape.builder()
            .id("foo.bar#Records")
            .member(listMember)
            .build()
        val model = createModelFromShapes(struct, list, listMember)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
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
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val setSymbol = provider.toSymbol(set)

        assertEquals("Set<Record>", setSymbol.name)
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
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val mapSymbol = provider.toSymbol(map)

        assertEquals("[String:Record]", mapSymbol.name)
        assertEquals(true, mapSymbol.isBoxed())
        assertEquals("nil", mapSymbol.defaultValue())
    }
}
