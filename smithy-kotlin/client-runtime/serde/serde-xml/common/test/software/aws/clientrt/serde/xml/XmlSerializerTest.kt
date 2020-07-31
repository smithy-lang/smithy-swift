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

import kotlin.test.Test
import kotlin.test.assertEquals
import software.aws.clientrt.serde.*

@OptIn(ExperimentalStdlibApi::class)
class XmlSerializerTest {

    @Test
    fun `can serialize class with class field`() {
        val a = A(
            B(2)
        )
        val xml = XmlSerializer()
        a.serialize(xml)
        assertEquals("""<b><value><value>2</value></value></b>""", xml.toByteArray().decodeToString())
    }

    class A(private val b: B) : SdkSerializable {
        companion object {
            val descriptorB: SdkFieldDescriptor = SdkFieldDescriptor("b")
        }

        override fun serialize(serializer: Serializer) {
            serializer.serializeStruct(descriptorB.serialName) {
                field(descriptorB, b)
            }
        }
    }

    data class B(private val value: Int) : SdkSerializable {
        companion object {
            val descriptorValue = SdkFieldDescriptor("value")
        }

        override fun serialize(serializer: Serializer) {
            serializer.serializeStruct(descriptorValue.serialName) {
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
        xml.serializeList {
            for (value in obj) {
                value.serialize(xml)
            }
        }
        assertEquals("""<list><value><value>1</value></value><value><value>2</value></value><value><value>3</value></value></list>""", xml.toByteArray().decodeToString())
    }

    /**
     * {    "A1":{"b":{      "value":1}},                      "A2":{"b":{      "value":2}},                      "A3":{"b":{      "value":3}}}
     * <map><A1>  <b> <value><value> 1</value></value></b></A1><A2>  <b> <value><value> 2</value></value></b></A2><A3>  <b> <value><value> 3</value></value></b></A3></map>
     * ^ --------------------------------- root container
     *                ^ ------------------ struct container
     *                        ^ ---------- primitive wrapper
     */
    @Test
    fun `can serialize map`() {
        val objs = mapOf("A1" to A(
            B(1)
        ), "A2" to A(
            B(
                2
            )
        ), "A3" to A(
            B(
                3
            )
        )
        )
        val xml = XmlSerializer()
        xml.serializeMap {
            for (obj in objs) {
                entry(obj.key, obj.value)
            }
        }
        assertEquals("""<map><A1><b><value><value>1</value></value></b></A1><A2><b><value><value>2</value></value></b></A2><A3><b><value><value>3</value></value></b></A3></map>""", xml.toByteArray().decodeToString())
    }

    @Test
    fun `can serialize all primitives`() {
        val xml = XmlSerializer()
        data.serialize(xml)

        assertEquals("""<struct><boolean>true</boolean><byte>10</byte><short>20</short><int>30</int><long>40</long><float>50.0</float><double>60.0</double><char>A</char><string>Str0</string></struct>""", xml.toByteArray().decodeToString())
    }
}

data class Primitives(
    val unit: Unit,
    val boolean: Boolean,
    val byte: Byte,
    val short: Short,
    val int: Int,
    val long: Long,
    val float: Float,
    val double: Double,
    val char: Char,
    val string: String,
    val unitNullable: Unit?
) : SdkSerializable {
    companion object {
        val descriptorUnit = SdkFieldDescriptor("unit")
        val descriptorBoolean = SdkFieldDescriptor("boolean")
        val descriptorByte = SdkFieldDescriptor("byte")
        val descriptorShort = SdkFieldDescriptor("short")
        val descriptorInt = SdkFieldDescriptor("int")
        val descriptorLong = SdkFieldDescriptor("long")
        val descriptorFloat = SdkFieldDescriptor("float")
        val descriptorDouble = SdkFieldDescriptor("double")
        val descriptorChar = SdkFieldDescriptor("char")
        val descriptorString = SdkFieldDescriptor("string")
        val descriptorUnitNullable = SdkFieldDescriptor("unitNullable")
    }

    override fun serialize(serializer: Serializer) {
        serializer.serializeStruct {
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
            serializeNull(descriptorUnitNullable)
        }
    }
}

val data = Primitives(
    Unit, true, 10, 20, 30, 40, 50f, 60.0, 'A', "Str0",
    null
)
