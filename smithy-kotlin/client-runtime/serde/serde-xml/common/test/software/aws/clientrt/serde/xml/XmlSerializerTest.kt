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

import software.aws.clientrt.serde.*
import kotlin.test.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalStdlibApi::class)
class XmlSerializerTest {

    @Test
    fun `can serialize class with class field`() {
        val a = A(
            B(2)
        )
        val xml = XmlSerializer()
        a.serialize(xml)
        assertEquals("""<a><b><v>2</v></b></a>""", xml.toByteArray().decodeToString())
    }

    class A(private val b: B) : SdkSerializable {
        companion object {
            val descriptorB: SdkFieldDescriptor = SdkFieldDescriptor("b", SerialKind.Object)

            val objectDescriptor: SdkObjectDescriptor = SdkObjectDescriptor.build {
                serialName = "a"
                field(descriptorB)
            }
        }

        override fun serialize(serializer: Serializer) {
            serializer.serializeStruct(objectDescriptor) {
                field(descriptorB, b)
            }
        }
    }

    data class B(private val value: Int) : SdkSerializable {
        companion object {
            val descriptorValue = SdkFieldDescriptor("v", SerialKind.Integer)

            val objectDescriptor: SdkObjectDescriptor = SdkObjectDescriptor.build {
                serialName = "b"
                field(descriptorValue)
            }
        }

        override fun serialize(serializer: Serializer) {
            serializer.serializeStruct(objectDescriptor) {
                field(descriptorValue, value)
            }
        }
    }

    @Test
    fun `can serialize list of classes`() {
        val obj = listOf(
            B(1),
            B(2),
            B(3)
        )
        val xml = XmlSerializer()
        xml.serializeList(SdkFieldDescriptor("list", SerialKind.List)) {
            for (value in obj) {
                value.serialize(xml)
            }
        }
        assertEquals("""<list><b><v>1</v></b><b><v>2</v></b><b><v>3</v></b></list>""", xml.toByteArray().decodeToString())
    }

    @Test
    fun `can serialize map`() {
        val objs = mapOf(
            "A1" to A(B(1)),
            "A2" to A(B(2)),
            "A3" to A(B(3))
        )
        val xml = XmlSerializer()
        xml.serializeMap(SdkFieldDescriptor("map", SerialKind.Map, 0, XmlMap("parent", "entry", "key", "value"))) {
            for (obj in objs) {
                entry(obj.key, obj.value)
            }
        }
        assertEquals("""<map><parent><entry><key>A1</key><value><a><b><v>1</v></b></a></value></entry><entry><key>A2</key><value><a><b><v>2</v></b></a></value></entry><entry><key>A3</key><value><a><b><v>3</v></b></a></value></entry></parent></map>""", xml.toByteArray().decodeToString())
    }

    @Test
    fun `can serialize flattened map`() {
        val objs = mapOf(
            "A1" to A(B(1)),
            "A2" to A(B(2)),
            "A3" to A(B(3))
        )
        val xml = XmlSerializer()
        xml.serializeMap(SdkFieldDescriptor("map", SerialKind.Map, 0, XmlMap(null, "entry", "key", "value", flattened = true))) {
            for (obj in objs) {
                entry(obj.key, obj.value)
            }
        }
        assertEquals("""<map><entry><key>A1</key><value><a><b><v>1</v></b></a></value></entry><entry><key>A2</key><value><a><b><v>2</v></b></a></value></entry><entry><key>A3</key><value><a><b><v>3</v></b></a></value></entry></map>""", xml.toByteArray().decodeToString())
    }

    @Test
    fun `can serialize all primitives`() {
        val xml = XmlSerializer()
        data.serialize(xml)

        assertEquals("""<struct><boolean>true</boolean><byte>10</byte><short>20</short><int>30</int><long>40</long><float>50.0</float><double>60.0</double><char>A</char><string>Str0</string><listInt><number>1</number><number>2</number><number>3</number></listInt></struct>""", xml.toByteArray().decodeToString())
    }

    /*
    data class C(private val value: Int) : SdkSerializable {
        companion object {
            val descriptorValue = SdkFieldDescriptor("v", SerialKind.Integer(Xml))

            val objectDescriptor: SdkObjectDescriptor = SdkObjectDescriptor.build {
                serialName("b")
                field(descriptorValue)
            }
        }

        override fun serialize(serializer: Serializer) {
            serializer.serializeStruct(objectDescriptor) {
                field(descriptorValue, value)
            }
        }
    }

     */
}

data class Primitives(
    //val unit: Unit,
    val boolean: Boolean,
    val byte: Byte,
    val short: Short,
    val int: Int,
    val long: Long,
    val float: Float,
    val double: Double,
    val char: Char,
    val string: String,
    //val unitNullable: Unit?,
    val listInt: List<Int>
) : SdkSerializable {
    companion object {
        val descriptorUnit = SdkFieldDescriptor("unit", SerialKind.Unit)
        val descriptorBoolean = SdkFieldDescriptor("boolean", SerialKind.Boolean)
        val descriptorByte = SdkFieldDescriptor("byte", SerialKind.Byte)
        val descriptorShort = SdkFieldDescriptor("short", SerialKind.Short)
        val descriptorInt = SdkFieldDescriptor("int", SerialKind.Integer)
        val descriptorLong = SdkFieldDescriptor("long", SerialKind.Long)
        val descriptorFloat = SdkFieldDescriptor("float", SerialKind.Float)
        val descriptorDouble = SdkFieldDescriptor("double", SerialKind.Double)
        val descriptorChar = SdkFieldDescriptor("char", SerialKind.Char)
        val descriptorString = SdkFieldDescriptor("string", SerialKind.String)
        // val descriptorUnitNullable = SdkFieldDescriptor("unitNullable")
        val descriptorListInt = SdkFieldDescriptor("listInt", SerialKind.List, 0, XmlList(elementName = "number"))
    }

    override fun serialize(serializer: Serializer) {
        serializer.serializeStruct(SdkFieldDescriptor("struct", SerialKind.Object)) {
            serializeNull(descriptorUnit)
            field(descriptorBoolean, boolean)
            field(descriptorByte, byte)
            field(descriptorShort, short)
            field(descriptorInt, int)
            field(descriptorLong, long)
            field(descriptorFloat, float)
            field(descriptorDouble, double)
            field(descriptorChar, char)
            field(descriptorString, string)
            // serializeNull(descriptorUnitNullable)
            listField(descriptorListInt) {
                for (value in listInt) {
                    serializeInt(value)
                }
            }
        }
    }
}

val data = Primitives(
    true, 10, 20, 30, 40, 50f, 60.0, 'A', "Str0",
    listOf(1,2,3)
)

