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
import software.aws.clientrt.serde.*
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@OptIn(ExperimentalStdlibApi::class)
class XmlDeserializerTest {
    @Test
    fun `it handles doubles`() {
        val payload = "<node>1.2</node>".encodeToByteArray()
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeStruct(SdkFieldDescriptor("node")).deserializeDouble()
        val expected = 1.2
        assertTrue(abs(actual - expected) <= 0.0001)
    }

    @Test
    fun `it handles floats`() {
        val payload = "<node>1.2</node>".encodeToByteArray()
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeStruct(SdkFieldDescriptor("node")).deserializeFloat()
        val expected = 1.2f
        assertTrue(abs(actual - expected) <= 0.0001f)
    }

    @Test
    fun `it handles int`() {
        val payload = "<node>${Int.MAX_VALUE}</node>".encodeToByteArray()
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeStruct(SdkFieldDescriptor("node")).deserializeInt()
        val expected = 2147483647
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles byte as number`() {
        val payload = "<node>1</node>".encodeToByteArray()
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeStruct(SdkFieldDescriptor("node")).deserializeByte()
        val expected: Byte = 1
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles short`() {
        val payload = "<node>${Short.MAX_VALUE}</node>".encodeToByteArray()
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeStruct(SdkFieldDescriptor("node")).deserializeShort()
        val expected: Short = 32767
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles long`() {
        val payload = "<node>${Long.MAX_VALUE}</node>".encodeToByteArray()
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeStruct(SdkFieldDescriptor("node")).deserializeLong()
        val expected = 9223372036854775807L
        assertEquals(expected, actual)
    }

    @Test
    fun `it handles bool`() {
        val payload = "<node>true</node>".encodeToByteArray()
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeStruct(SdkFieldDescriptor("node")).deserializeBool()
        assertTrue(actual)
    }

    @Test
    fun `it handles lists`() {
        val payload = """
            <list>
                <element>1</element>
                <element>2</element>
                <element>3</element>
            </list>
        """.flatten().encodeToByteArray()
        val listWrapperFieldDescriptor = SdkFieldDescriptor("list")
        val listElementFieldDescriptor = SdkFieldDescriptor("element")
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeList(listWrapperFieldDescriptor) {
            val list = mutableListOf<Int>()
            while (hasNextElement(listElementFieldDescriptor)) {
                list.add(deserializeInt())
            }
            return@deserializeList list
        }
        val expected = listOf(1, 2, 3)
        actual.shouldContainExactly(expected)
    }

    @Test
    fun `it handles maps`() {
        val payload = """
            <Foo>
                <values>
                    <entry>
                        <key>key1</key>
                        <value>1</value>
                    </entry>
                    <entry>
                        <key>key2</key>
                        <value>2</value>
                    </entry>
                </values>
            </Foo>
        """.flatten().encodeToByteArray()
        val fieldDescriptor = SdkFieldDescriptor("Foo")
        val containerFieldDescriptor = SdkFieldDescriptor("values")
        val entryFieldDescriptor = SdkFieldDescriptor("entry")
        val keyFieldDescriptor = SdkFieldDescriptor("key")
        val valueFieldDescriptor = SdkFieldDescriptor("value")
        val deserializer = XmlDeserializer(payload)
        var actual = mapOf<String, Int>()
        deserializer.deserializeStruct(fieldDescriptor) {
            actual = deserializer.deserializeMap(containerFieldDescriptor) {
                val map = mutableMapOf<String, Int>()
                while (hasNextEntry(entryFieldDescriptor)) {
                    val key = key(keyFieldDescriptor)
                    val value = deserializer.deserializeStruct(valueFieldDescriptor).deserializeInt()
                    map[key] = value
                }
                return@deserializeMap map
            }
        }
        val expected = mapOf("key1" to 1, "key2" to 2)
        actual.shouldContainExactly(expected)
    }

    // https://awslabs.github.io/smithy/1.0/spec/core/xml-traits.html#flattened-map-serialization
    @Test
    fun `it handles flat maps`() {
        val payload = """
            <Bar>
                <flatMap>
                    <key>key1</key>
                    <value>1</value>
                </flatMap>
                <flatMap>
                    <key>key2</key>
                    <value>2</value>
                </flatMap>
                <flatMap>
                    <key>key3</key>
                    <value>3</value>
                </flatMap>
            </Bar>
        """.flatten().encodeToByteArray()
        val containerFieldDescriptor = SdkFieldDescriptor("Bar")
        val entryFieldDescriptor = SdkFieldDescriptor("flatMap")
        val keyFieldDescriptor = SdkFieldDescriptor("key")
        val valueFieldDescriptor = SdkFieldDescriptor("value")
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeMap(containerFieldDescriptor) {
            val map = mutableMapOf<String, Int>()
            while (hasNextEntry(entryFieldDescriptor)) {
                val key = key(keyFieldDescriptor)
                val value = deserializer.deserializeStruct(valueFieldDescriptor).deserializeInt()
                map[key] = value
            }
            return@deserializeMap map
        }
        val expected = mapOf("key1" to 1, "key2" to 2, "key3" to 3)
        actual.shouldContainExactly(expected)
    }


    class BasicStructTest {
        var x: Int? = null
        var y: Int? = null
        var unknownFieldCount: Int = 0

        companion object {
            val X_DESCRIPTOR = SdkFieldDescriptor("x")
            val Y_DESCRIPTOR = SdkFieldDescriptor("y")
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
                field(X_DESCRIPTOR)
                field(Y_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): BasicStructTest {
                val result = BasicStructTest()
                deserializer.deserializeStruct(SdkFieldDescriptor("payload")) {
                    loop@ while (true) {
                        when (findNextFieldIndex(OBJ_DESCRIPTOR)) {
                            X_DESCRIPTOR.index -> result.x = deserializer.deserializeStruct(X_DESCRIPTOR).deserializeInt()
                            Y_DESCRIPTOR.index -> result.y = deserializer.deserializeStruct(Y_DESCRIPTOR).deserializeInt()
                            null -> break@loop
                            Deserializer.FieldIterator.UNKNOWN_FIELD -> {
                                result.unknownFieldCount++
                            }
                            else -> throw XmlGenerationException(IllegalStateException("unexpected field in BasicStructTest deserializer"))
                        }
                        skipValue() // This performs two tasks.  For unknown fields, it consumes the node.  For found fields, it consumes the end token.
                    }
                }
                return result
            }
        }
    }

    @Test
    fun `it handles basic structs`() {
        val payload = """
            <payload>
                <x>1</x>
                <y>2</y>
            </payload>
        """.flatten().encodeToByteArray()

        val deserializer = XmlDeserializer(payload)
        val bst = BasicStructTest.deserialize(deserializer)

        assertEquals(1, bst.x)
        assertEquals(2, bst.y)
    }

    @Test
    fun `it handles list of objects`() {
        val payload = """
            <list>
                <payload>
                    <x>1</x>
                    <y>2</y>
                </payload>
                <payload>
                    <x>3</x>
                    <y>4</y>
                </payload>
            </list>
        """.flatten().encodeToByteArray()
        val listFieldDescriptor = SdkFieldDescriptor("list")
        val objectFieldDescriptor = SdkFieldDescriptor("payload")
        val deserializer = XmlDeserializer(payload)
        val actual = deserializer.deserializeList(listFieldDescriptor) {
            val list = mutableListOf<BasicStructTest>()
            while (hasNextElement(objectFieldDescriptor)) {
                val obj = BasicStructTest()
                obj.x = deserializer.deserializeStruct(BasicStructTest.X_DESCRIPTOR).deserializeInt()
                obj.y = deserializer.deserializeStruct(BasicStructTest.Y_DESCRIPTOR).deserializeInt()
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
        val payload = """
            <payload>
                <x>1</x>
                <z>unknown field</z>
                <y>2</y>
            </payload>
        """.flatten().encodeToByteArray()

        val deserializer = XmlDeserializer(payload)
        val bst = BasicStructTest.deserialize(deserializer)

        assertTrue(bst.unknownFieldCount == 1, "unknown field not enumerated")
    }

    class Nested2 {
        var list2: List<String>? = null
        var int2: Int? = null
        companion object {
            val LIST2_FIELD_DESCRIPTOR = SdkFieldDescriptor("list2")
            val LIST_ELEMENT_FIELD_DESCRIPTOR = SdkFieldDescriptor("element")
            val INT2_FIELD_DESCRIPTOR = SdkFieldDescriptor("int2")
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build() {
                field(LIST2_FIELD_DESCRIPTOR)
                field(INT2_FIELD_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): Nested2 {
                val struct = deserializer.deserializeStruct(SdkFieldDescriptor("nested2"))
                val nested2 = Nested2()
                loop@ while (true) {
                    when (struct.findNextFieldIndex(OBJ_DESCRIPTOR)) {
                        LIST2_FIELD_DESCRIPTOR.index -> nested2.list2 = deserializer.deserializeList(LIST2_FIELD_DESCRIPTOR) {
                            val list = mutableListOf<String>()
                            while (hasNextElement(LIST_ELEMENT_FIELD_DESCRIPTOR)) {
                                list.add(deserializer.deserializeString())
                            }
                            struct.skipValue()
                            return@deserializeList list
                        }
                        INT2_FIELD_DESCRIPTOR.index -> nested2.int2 = deserializer.deserializeStruct(INT2_FIELD_DESCRIPTOR).deserializeInt()
                        // deeply nested unknown field
                        Deserializer.FieldIterator.UNKNOWN_FIELD -> {
                            //here we need to recurse out of the unknown node, the following doesnt work:
                            struct.skipValue()
                        }
                        null -> break@loop
                        else -> throw XmlGenerationException(IllegalStateException("unexpected field during test"))
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
            val NESTED2_FIELD_DESCRIPTOR = SdkFieldDescriptor("nested2")
            val BOOL2_FIELD_DESCRIPTOR = SdkFieldDescriptor("bool2")
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build() {
                field(NESTED2_FIELD_DESCRIPTOR)
                field(BOOL2_FIELD_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): Nested {
                val struct = deserializer.deserializeStruct(SdkFieldDescriptor("nested"))
                val nested = Nested()
                loop@ while (true) {
                    when (struct.findNextFieldIndex(OBJ_DESCRIPTOR)) {
                        NESTED2_FIELD_DESCRIPTOR.index -> {
                            nested.nested2 = Nested2.deserialize(deserializer)
                            //struct.skipValue()
                        }
                        BOOL2_FIELD_DESCRIPTOR.index -> nested.bool2 = deserializer.deserializeStruct(BOOL2_FIELD_DESCRIPTOR).deserializeBool()
                        null -> break@loop
                        else -> throw XmlGenerationException(IllegalStateException("unexpected field during test"))
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
            val INT_FIELD_DESCRIPTOR = SdkFieldDescriptor("int")
            val LONG_FIELD_DESCRIPTOR = SdkFieldDescriptor("long")
            val SHORT_FIELD_DESCRIPTOR = SdkFieldDescriptor("short")
            val BOOL_FIELD_DESCRIPTOR = SdkFieldDescriptor("bool")
            val STR_FIELD_DESCRIPTOR = SdkFieldDescriptor("str")
            val LIST_FIELD_DESCRIPTOR = SdkFieldDescriptor("list")
            val LIST_ELEMENT_FIELD_DESCRIPTOR = SdkFieldDescriptor("element")
            val DOUBLE_FIELD_DESCRIPTOR = SdkFieldDescriptor("double")
            val NESTED_FIELD_DESCRIPTOR = SdkFieldDescriptor("nested")
            val FLOAT_FIELD_DESCRIPTOR = SdkFieldDescriptor("float")
            val MAP_FIELD_DESCRIPTOR = SdkFieldDescriptor("map")
            val MAP_ENTRY_FIELD_DESCRIPTOR = SdkFieldDescriptor("entry")
            val MAP_KEY_FIELD_DESCRIPTOR = SdkFieldDescriptor("key")
            val MAP_VALUE_FIELD_DESCRIPTOR = SdkFieldDescriptor("value")

            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build() {
                field(INT_FIELD_DESCRIPTOR)
                field(LONG_FIELD_DESCRIPTOR)
                field(SHORT_FIELD_DESCRIPTOR)
                field(BOOL_FIELD_DESCRIPTOR)
                field(STR_FIELD_DESCRIPTOR)
                field(LIST_ELEMENT_FIELD_DESCRIPTOR)
                field(LIST_FIELD_DESCRIPTOR)
                field(DOUBLE_FIELD_DESCRIPTOR)
                field(NESTED_FIELD_DESCRIPTOR)
                field(FLOAT_FIELD_DESCRIPTOR)
                field(MAP_FIELD_DESCRIPTOR)
                field(MAP_ENTRY_FIELD_DESCRIPTOR)
                field(MAP_KEY_FIELD_DESCRIPTOR)
                field(MAP_VALUE_FIELD_DESCRIPTOR)
            }
        }
    }

    @Test
    fun `it handles kitchen sink`() {
        val payload = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <payload>
            <int>1</int>
            <long>2</long>
            <short>3</short>
            <bool>false</bool>
            <str>a string</str>
            <list>
                <element>10</element>
                <element>11</element>
                <element>12</element>
            </list>
            <double>7.5</double>
            <nested>
                <nested2>
                    <list2>
                        <element>x</element>
                        <element>y</element>
                    </list2>
                    <unknown>
                        <a>a</a>
                        <b>b</b>
                        <c>
                            <element>d</element>
                            <element>e</element>
                            <element>f</element>
                        </c>
                        <g>
                            <h>h</h>
                            <i>i</i>
                        </g>
                    </unknown>
                    <int2>4</int2>
                </nested2>
                <bool2>true</bool2>
            </nested>
            <float>0.2</float>
            <map>
                <entry>
                    <key>key1</key>
                    <value>value1</value>
                </entry>
                <entry>
                    <key>key2</key>
                    <value>value2</value>
                </entry>
            </map>
        </payload>
        """.flatten().encodeToByteArray()

        val deserializer = XmlDeserializer(payload)
        val struct = deserializer.deserializeStruct(SdkFieldDescriptor("payload"))
        val sink = KitchenSinkTest()
        loop@ while (true) {
            when (struct.findNextFieldIndex(KitchenSinkTest.OBJ_DESCRIPTOR)) {
                KitchenSinkTest.INT_FIELD_DESCRIPTOR.index -> sink.intField = deserializer.deserializeStruct(KitchenSinkTest.INT_FIELD_DESCRIPTOR).deserializeInt()
                KitchenSinkTest.LONG_FIELD_DESCRIPTOR.index -> sink.longField = deserializer.deserializeStruct(KitchenSinkTest.LONG_FIELD_DESCRIPTOR).deserializeLong()
                KitchenSinkTest.SHORT_FIELD_DESCRIPTOR.index -> sink.shortField = deserializer.deserializeStruct(KitchenSinkTest.LONG_FIELD_DESCRIPTOR).deserializeShort()
                KitchenSinkTest.BOOL_FIELD_DESCRIPTOR.index -> sink.boolField = deserializer.deserializeStruct(KitchenSinkTest.LONG_FIELD_DESCRIPTOR).deserializeBool()
                KitchenSinkTest.STR_FIELD_DESCRIPTOR.index -> sink.strField = deserializer.deserializeStruct(KitchenSinkTest.LONG_FIELD_DESCRIPTOR).deserializeString()
                KitchenSinkTest.LIST_FIELD_DESCRIPTOR.index -> sink.listField = deserializer.deserializeList(KitchenSinkTest.LIST_FIELD_DESCRIPTOR) {
                    val list = mutableListOf<Int>()
                    while (hasNextElement(KitchenSinkTest.LIST_ELEMENT_FIELD_DESCRIPTOR)) {
                        list.add(deserializer.deserializeInt())
                    }
                    return@deserializeList list
                }
                KitchenSinkTest.DOUBLE_FIELD_DESCRIPTOR.index -> sink.doubleField = deserializer.deserializeStruct(KitchenSinkTest.LONG_FIELD_DESCRIPTOR).deserializeDouble()
                KitchenSinkTest.NESTED_FIELD_DESCRIPTOR.index -> sink.nestedField = Nested.deserialize(deserializer)
                KitchenSinkTest.FLOAT_FIELD_DESCRIPTOR.index -> sink.floatField = deserializer.deserializeStruct(KitchenSinkTest.FLOAT_FIELD_DESCRIPTOR).deserializeFloat()
                KitchenSinkTest.MAP_FIELD_DESCRIPTOR.index -> sink.mapField = deserializer.deserializeMap(KitchenSinkTest.MAP_FIELD_DESCRIPTOR) {
                    val map = mutableMapOf<String, String>()
                    while (hasNextEntry(KitchenSinkTest.MAP_ENTRY_FIELD_DESCRIPTOR)) {
                        val key = key(KitchenSinkTest.MAP_KEY_FIELD_DESCRIPTOR)
                        val value = deserializer.deserializeStruct(KitchenSinkTest.MAP_VALUE_FIELD_DESCRIPTOR).deserializeString()
                        map[key] = value
                    }
                    return@deserializeMap map
                }
                null -> break@loop
                else -> throw XmlGenerationException(IllegalStateException("unexpected field during test"))
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

    class HostedZoneConfig private constructor(builder: BuilderImpl) {
        val comment: String? = builder.comment

        companion object {
            val COMMENT_DESCRIPTOR = SdkFieldDescriptor("Comment")
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
                field(COMMENT_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): HostedZoneConfig {
                val builder = BuilderImpl()
                deserializer.deserializeStruct(SdkFieldDescriptor("payload")) {
                    loop@ while (true) {
                        when (findNextFieldIndex(OBJ_DESCRIPTOR)) {
                            COMMENT_DESCRIPTOR.index -> builder.comment = deserializer.deserializeStruct(COMMENT_DESCRIPTOR).deserializeString()
                            null -> break@loop
                            Deserializer.FieldIterator.UNKNOWN_FIELD -> {}
                            else -> throw XmlGenerationException(IllegalStateException("unexpected field index in HostedZoneConfig deserializer"))
                        }
                        skipValue()
                    }
                }
                return HostedZoneConfig(builder)
            }

            operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        }

        interface Builder {
            fun build(): HostedZoneConfig
            // TODO - Java fill in Java builder
        }

        interface DslBuilder {
            var comment: String?
        }

        private class BuilderImpl : Builder, DslBuilder {
            override var comment: String? = null

            override fun build(): HostedZoneConfig = HostedZoneConfig(this)
        }
    }

    class CreateHostedZoneRequest private constructor(builder: BuilderImpl) {
        val name: String? = builder.name
        val callerReference: String? = builder.callerReference
        val hostedZoneConfig: HostedZoneConfig? = builder.hostedZoneConfig

        companion object {
            val NAME_DESCRIPTOR = SdkFieldDescriptor("Name")
            val CALLER_REFERENCE_DESCRIPTOR = SdkFieldDescriptor("CallerReference")
            val HOSTED_ZONE_DESCRIPTOR = SdkFieldDescriptor("HostedZoneConfig")
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
                field(NAME_DESCRIPTOR)
                field(CALLER_REFERENCE_DESCRIPTOR)
                field(HOSTED_ZONE_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): CreateHostedZoneRequest {
                val builder = BuilderImpl()
                deserializer.deserializeStruct(SdkFieldDescriptor("payload")) {
                    loop@ while (true) {
                        when (findNextFieldIndex(OBJ_DESCRIPTOR)) {
                            NAME_DESCRIPTOR.index -> builder.name = deserializer.deserializeStruct(NAME_DESCRIPTOR).deserializeString()
                            CALLER_REFERENCE_DESCRIPTOR.index -> builder.callerReference = deserializer.deserializeStruct(CALLER_REFERENCE_DESCRIPTOR).deserializeString()
                            HOSTED_ZONE_DESCRIPTOR.index -> builder.hostedZoneConfig = HostedZoneConfig.deserialize(deserializer)
                            null -> break@loop
                            Deserializer.FieldIterator.UNKNOWN_FIELD -> skipValue()
                            else -> throw XmlGenerationException(IllegalStateException("unexpected field index in CreateHostedZoneRequest deserializer"))
                        }
                    }
                }
                return builder.build()
            }

            operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        }

        interface Builder {
            fun build(): CreateHostedZoneRequest
            // TODO - Java fill in Java builder
        }

        interface DslBuilder {
            var name: String?
            var callerReference: String?
            var hostedZoneConfig: HostedZoneConfig?
        }

        private class BuilderImpl : Builder, DslBuilder {
            override var name: String? = null
            override var callerReference: String? = null
            override var hostedZoneConfig: HostedZoneConfig? = null

            override fun build(): CreateHostedZoneRequest = CreateHostedZoneRequest(this)
        }
    }

    @Test
    fun `it handles Route 53 XML`() {
        val testXml = """
            <?xml version="1.0" encoding="UTF-8"?><!--
              ~ Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
              ~ SPDX-License-Identifier: Apache-2.0.
              -->
            
            <CreateHostedZoneRequest xmlns="https://route53.amazonaws.com/doc/2013-04-01/">
                <Name>java.sdk.com.</Name>
                <CallerReference>a322f752-8156-4746-8c04-e174ca1f51ce</CallerReference>
                <HostedZoneConfig>
                    <Comment>comment</Comment>
                </HostedZoneConfig>
            </CreateHostedZoneRequest>
        """.flatten()

        val unit = XmlDeserializer(testXml.encodeToByteArray())

        val createHostedZoneRequest = CreateHostedZoneRequest.deserialize(unit)

        assertTrue(createHostedZoneRequest.name == "java.sdk.com.")
        assertTrue(createHostedZoneRequest.callerReference == "a322f752-8156-4746-8c04-e174ca1f51ce")
        assertNotNull(createHostedZoneRequest.hostedZoneConfig)
        assertTrue(createHostedZoneRequest.hostedZoneConfig.comment == "comment")
    }
}

// Remove linefeeds in a string
private fun String.flatten(): String =
    this.trimIndent().lines().joinToString(separator = "") { line -> line.trim() }