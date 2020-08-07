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
package software.aws.clientrt.serde.xml

import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.maps.shouldContainExactly
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import software.aws.clientrt.serde.*

@OptIn(ExperimentalStdlibApi::class)
class XmlDeserializerTest {
    @Test
    fun `it handles doubles`() {
        val payload = "<node>1.2</node>".encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeDouble(XmlFieldDescriptor("node", 0))
        val expected = 1.2
        assertTrue(abs(actual - expected) <= 0.0001)
    }

    @Test
    fun `it handles floats`() {
        val payload = "<node>1.2</node>".encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeFloat(XmlFieldDescriptor("node", 0))
        val expected = 1.2f
        assertTrue(abs(actual - expected) <= 0.0001f)
    }

    @Test
    fun `it handles int`() {
        val payload = "<node>1</node>".encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeInt(XmlFieldDescriptor("node", 0))
        val expected = 1
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles byte as number`() {
        val payload = "<node>1</node>".encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeByte(XmlFieldDescriptor("node", 0))
        val expected: Byte = 1
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles short`() {
        val payload = "<node>1</node>".encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeShort(XmlFieldDescriptor("node",  0))
        val expected: Short = 1
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles long`() {
        val payload = "<node>12</node>".encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeLong(XmlFieldDescriptor("node", 0))
        val expected = 12L
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles bool`() {
        val payload = "<node>true</node>".encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeBool(XmlFieldDescriptor("node", 0))
        assertTrue(actual)
    }

    @Test
    fun `it handles lists`() {
        val payload = """<list><element>1</element><element>2</element><element>3</element></list>""".trimIndent().encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeList(XmlFieldDescriptor("list", 0)) {
            val list = mutableListOf<Int>()
            while (next() != Deserializer.ElementIterator.EXHAUSTED) {
                list.add(deserializeInt(XmlFieldDescriptor("element", 0)))
            }
            return@deserializeList list
        }
        val expected = listOf(1, 2, 3)
        actual.shouldContainExactly(expected)
        println(actual)
    }

    @Test
    fun `it handles maps`() {
        val payload = """<map><entry><key>key1</key><value>1</value></entry><entry><key>key2</key><value>2</value></entry></map>""".trimIndent().encodeToByteArray()
        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeMap(XmlFieldDescriptor("map", 0)) {
            val map = mutableMapOf<String, Int>()
            while (next() != Deserializer.EntryIterator.EXHAUSTED) {
                deserializer.deserializeStruct(XmlFieldDescriptor("entry", 0)) {
                    map[key(XmlFieldDescriptor("key", 0))] = deserializeInt(XmlFieldDescriptor("value", 0))
                }
            }
            return@deserializeMap map
        }
        val expected = mapOf("key1" to 1, "key2" to 2)
        actual.shouldContainExactly(expected)
    }

    class BasicStructTest {
        var x: Int? = null
        var y: Int? = null
        var unknownFieldCount: Int = 0

        companion object {
            val X_DESCRIPTOR = XmlFieldDescriptor("x", 1)
            val Y_DESCRIPTOR = XmlFieldDescriptor("y", 2)
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
                field(X_DESCRIPTOR)
                field(Y_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): BasicStructTest {
                val result = BasicStructTest()
                deserializer.deserializeStruct(XmlFieldDescriptor("payload", 0)) {
                    loop@ while (true) {
                        when (nextField(OBJ_DESCRIPTOR)) {
                            X_DESCRIPTOR.index -> result.x = deserializeInt(X_DESCRIPTOR)
                            Y_DESCRIPTOR.index -> result.y = deserializeInt(Y_DESCRIPTOR)
                            Deserializer.FieldIterator.EXHAUSTED -> break@loop
                            Deserializer.FieldIterator.UNKNOWN_FIELD -> {
                                result.unknownFieldCount++
                                skipValue()
                            }
                            else -> throw RuntimeException("unexpected field in BasicStructTest deserializer")
                        }
                    }
                }
                return result
            }
        }
    }

    @Test
    fun `it handles basic structs`() {
        val payload = """<payload><x>1</x><y>2</y></payload>""".trimIndent().encodeToByteArray()

        val deserializer = XmlDeserializer2(payload)
        val bst = BasicStructTest.deserialize(deserializer)

        assertEquals(1, bst.x)
        assertEquals(2, bst.y)
    }

    @Test
    fun `it handles list of objects`() {
        val payload = """<list><payload><x>1</x><y>2</y></payload><payload><x>3</x><y>4</y></payload></list>""".trimIndent().encodeToByteArray()

        val deserializer = XmlDeserializer2(payload)
        val actual = deserializer.deserializeList(XmlFieldDescriptor("list", 0)) {
            val list = mutableListOf<BasicStructTest>()
            while (next() != Deserializer.ElementIterator.EXHAUSTED) {
                val obj = BasicStructTest()
                deserializer.deserializeStruct(XmlFieldDescriptor("payload", 0)) {
                    obj.x = deserializeInt(BasicStructTest.X_DESCRIPTOR)
                    obj.y = deserializeInt(BasicStructTest.Y_DESCRIPTOR)
                }
                list.add(obj)
            }
            return@deserializeList list
        }
        assertEquals(2, actual.size)
        assertEquals(1, actual[0].x)
        assertEquals(2, actual[0].y)
        assertEquals(3, actual[1].x)
        assertEquals(4, actual[1].y)
    }

    @Test
    fun `it enumerates unknown struct fields`() {
        val payload = """<payload><x>1</x><z>unknown field</z><y>2</y></payload>""".trimIndent().encodeToByteArray()

        val deserializer = XmlDeserializer2(payload)
        val bst = BasicStructTest.deserialize(deserializer)

        assertTrue(bst.unknownFieldCount == 1, "unknown field not enumerated")
    }

    class Nested2 {
        var list2: List<String>? = null
        var int2: Int? = null
        companion object {
            val LIST2_FIELD_DESCRIPTOR = XmlFieldDescriptor("list2", 0)
            val INT2_FIELD_DESCRIPTOR = XmlFieldDescriptor("int2", 1)
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build() {
                field(LIST2_FIELD_DESCRIPTOR)
                field(INT2_FIELD_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): Nested2 {
                val struct = deserializer.deserializeStruct(XmlFieldDescriptor("nested2"))
                val nested2 = Nested2()
                loop@ while (true) {
                    when (struct.nextField(OBJ_DESCRIPTOR)) {
                        LIST2_FIELD_DESCRIPTOR.index -> nested2.list2 = deserializer.deserializeList(LIST2_FIELD_DESCRIPTOR) {
                            val list = mutableListOf<String>()
                            while (next() != Deserializer.ElementIterator.EXHAUSTED) {
                                list.add(deserializeString(XmlFieldDescriptor("element")))
                            }
                            struct.skipValue()
                            return@deserializeList list
                        }
                        INT2_FIELD_DESCRIPTOR.index -> nested2.int2 = struct.deserializeInt(INT2_FIELD_DESCRIPTOR)
                        // deeply nested unknown field
                        Deserializer.FieldIterator.UNKNOWN_FIELD -> {
                            //here we need to recurse out of the unknown node, the following doesnt work:
                            struct.skipValue()
                        }
                        Deserializer.FieldIterator.EXHAUSTED -> break@loop
                        else -> throw RuntimeException("unexpected field during test")
                    }
                }
                return nested2
            }
        }
    }

    class Nested {
        var nested2: Nested2? = null
        var bool2: Boolean? = null

        companion object {
            val NESTED2_FIELD_DESCRIPTOR = XmlFieldDescriptor("nested2", 0)
            val BOOL2_FIELD_DESCRIPTOR = XmlFieldDescriptor("bool2", 1)
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build() {
                field(NESTED2_FIELD_DESCRIPTOR)
                field(BOOL2_FIELD_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): Nested {
                val struct = deserializer.deserializeStruct(XmlFieldDescriptor("nested"))
                val nested = Nested()
                loop@ while (true) {
                    when (struct.nextField(OBJ_DESCRIPTOR)) {
                        NESTED2_FIELD_DESCRIPTOR.index -> {
                            nested.nested2 = Nested2.deserialize(deserializer)
                            //struct.skipValue()
                        }
                        BOOL2_FIELD_DESCRIPTOR.index -> nested.bool2 = deserializer.deserializeBool(
                            BOOL2_FIELD_DESCRIPTOR)
                        Deserializer.FieldIterator.EXHAUSTED -> break@loop
                        else -> throw RuntimeException("unexpected field during test")
                    }
                }
                return nested
            }
        }
    }

    class KitchenSinkTest {
        var intField: Int? = null
        var longField: Long? = null
        var shortField: Short? = null
        var boolField: Boolean? = null
        var strField: String? = null
        var listField: List<Int>? = null
        var doubleField: Double? = null
        var nestedField: Nested? = null
        var floatField: Float? = null
        var mapField: Map<String, String>? = null

        companion object {
            val INT_FIELD_DESCRIPTOR = XmlFieldDescriptor("int", 0)
            val LONG_FIELD_DESCRIPTOR = XmlFieldDescriptor("long", 1)
            val SHORT_FIELD_DESCRIPTOR = XmlFieldDescriptor("short", 2)
            val BOOL_FIELD_DESCRIPTOR = XmlFieldDescriptor("bool", 3)
            val STR_FIELD_DESCRIPTOR = XmlFieldDescriptor("str", 4)
            val LIST_FIELD_DESCRIPTOR = XmlFieldDescriptor("list", 5)
            val DOUBLE_FIELD_DESCRIPTOR = XmlFieldDescriptor("double", 6)
            val NESTED_FIELD_DESCRIPTOR = XmlFieldDescriptor("nested", 7)
            val FLOAT_FIELD_DESCRIPTOR = XmlFieldDescriptor("float", 8)
            val MAP_FIELD_DESCRIPTOR = XmlFieldDescriptor("map", 9)

            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build() {
                field(INT_FIELD_DESCRIPTOR)
                field(LONG_FIELD_DESCRIPTOR)
                field(SHORT_FIELD_DESCRIPTOR)
                field(BOOL_FIELD_DESCRIPTOR)
                field(STR_FIELD_DESCRIPTOR)
                field(LIST_FIELD_DESCRIPTOR)
                field(DOUBLE_FIELD_DESCRIPTOR)
                field(NESTED_FIELD_DESCRIPTOR)
                field(FLOAT_FIELD_DESCRIPTOR)
                field(MAP_FIELD_DESCRIPTOR)
            }
        }
    }

    @Test
    fun `it handles kitchen sink`() {
        val payload = """
        <?xml version="1.0" encoding="UTF-8" ?><payload><int>1</int><long>2</long><short>3</short><bool>false</bool><str>a string</str><list><element>10</element><element>11</element><element>12</element></list><double>7.5</double><nested><nested2><list2><element>x</element><element>y</element></list2><unknown><a>a</a><b>b</b><c><element>d</element><element>e</element><element>f</element></c><g><h>h</h><i>i</i></g></unknown><int2>4</int2></nested2><bool2>true</bool2></nested><float>0.2</float><map><entry><key>key1</key><value>value1</value></entry><entry><key>key2</key><value>value2</value></entry></map></payload>
        """.trimIndent().encodeToByteArray()

        val deserializer = XmlDeserializer2(payload)
        val struct = deserializer.deserializeStruct(XmlFieldDescriptor("payload", 0))
        val sink = KitchenSinkTest()
        loop@ while (true) {
            when (struct.nextField(KitchenSinkTest.OBJ_DESCRIPTOR)) {
                KitchenSinkTest.INT_FIELD_DESCRIPTOR.index -> sink.intField = struct.deserializeInt(KitchenSinkTest.INT_FIELD_DESCRIPTOR)
                KitchenSinkTest.LONG_FIELD_DESCRIPTOR.index -> sink.longField = struct.deserializeLong(KitchenSinkTest.LONG_FIELD_DESCRIPTOR)
                KitchenSinkTest.SHORT_FIELD_DESCRIPTOR.index -> sink.shortField = struct.deserializeShort(KitchenSinkTest.SHORT_FIELD_DESCRIPTOR)
                KitchenSinkTest.BOOL_FIELD_DESCRIPTOR.index -> sink.boolField = struct.deserializeBool(KitchenSinkTest.BOOL_FIELD_DESCRIPTOR)
                KitchenSinkTest.STR_FIELD_DESCRIPTOR.index -> sink.strField = struct.deserializeString(KitchenSinkTest.STR_FIELD_DESCRIPTOR)
                KitchenSinkTest.LIST_FIELD_DESCRIPTOR.index -> sink.listField = deserializer.deserializeList(KitchenSinkTest.LIST_FIELD_DESCRIPTOR) {
                    val list = mutableListOf<Int>()
                    while (next() != Deserializer.ElementIterator.EXHAUSTED) {
                        list.add(deserializeInt(XmlFieldDescriptor("element", 0)))
                    }
                    return@deserializeList list
                }
                KitchenSinkTest.DOUBLE_FIELD_DESCRIPTOR.index -> sink.doubleField = struct.deserializeDouble(KitchenSinkTest.DOUBLE_FIELD_DESCRIPTOR)
                KitchenSinkTest.NESTED_FIELD_DESCRIPTOR.index -> sink.nestedField = Nested.deserialize(deserializer)
                KitchenSinkTest.FLOAT_FIELD_DESCRIPTOR.index -> sink.floatField = struct.deserializeFloat(KitchenSinkTest.FLOAT_FIELD_DESCRIPTOR)
                KitchenSinkTest.MAP_FIELD_DESCRIPTOR.index -> sink.mapField = deserializer.deserializeMap(KitchenSinkTest.MAP_FIELD_DESCRIPTOR) {
                    val map = mutableMapOf<String, String>()
                    while (next() != Deserializer.EntryIterator.EXHAUSTED) {
                        deserializer.deserializeStruct(XmlFieldDescriptor("entry", 0)) {
                            map[key(XmlFieldDescriptor("key"))] = deserializeString(XmlFieldDescriptor("value"))
                        }
                    }
                    return@deserializeMap map
                }
                Deserializer.FieldIterator.EXHAUSTED -> break@loop
                else -> throw RuntimeException("unexpected field during test")
            }
        }

        assertEquals(1, sink.intField)
        assertEquals(2L, sink.longField)
        assertEquals(3.toShort(), sink.shortField)
        assertEquals(false, sink.boolField)
        assertEquals("a string", sink.strField)
        sink.listField.shouldContainExactly(listOf(10, 11, 12))
        assertTrue(abs(sink.doubleField!! - 7.5) <= 0.0001)

        assertEquals(sink.nestedField!!.nested2!!.int2, 4)
        sink.nestedField!!.nested2!!.list2.shouldContainExactly(listOf("x", "y"))
        assertEquals(sink.nestedField!!.bool2, true)

        assertTrue(abs(sink.floatField!! - 0.2f) <= 0.0001f)
        val expectedMap = mapOf("key1" to "value1", "key2" to "value2")
        sink.mapField!!.shouldContainExactly(expectedMap)
    }
}
