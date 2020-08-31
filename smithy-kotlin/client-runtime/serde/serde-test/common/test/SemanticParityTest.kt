/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import software.aws.clientrt.serde.*
import software.aws.clientrt.serde.json.JsonDeserializer
import software.aws.clientrt.serde.json.JsonSerializer
import software.aws.clientrt.serde.xml.XmlDeserializer
import software.aws.clientrt.serde.xml.XmlList
import software.aws.clientrt.serde.xml.XmlSerializer
import kotlin.test.Test
import kotlin.test.assertEquals

@ExperimentalStdlibApi
class SemanticParityTest {

    @Test
    fun `xml deserializes into object form then deserializes to json then serializes to object form then deserializes to original xml`() {
        for (test in getTests()) {
            //xml
            val xmlPayload = test.xmlSerialization

            //object
            val xmlDeserializer = XmlDeserializer(xmlPayload.encodeToByteArray())
            val bst = test.deserialize(xmlDeserializer)

            //json
            val jsonSerializer = JsonSerializer()
            bst.serialize(jsonSerializer)
            val jsonPayload = jsonSerializer.toByteArray().decodeToString()

            //object
            val jsonDeserializer = JsonDeserializer(jsonPayload.encodeToByteArray())
            val bst2 = test.deserialize(jsonDeserializer)

            assertEquals(bst, bst2)

            //xml - compare
            val xmlSerializer = XmlSerializer()
            bst2.serialize(xmlSerializer)
            val xmlPayload2 = xmlSerializer.toByteArray().decodeToString()

            assertEquals(xmlPayload, xmlPayload2)
        }
    }

    @Test
    fun `json deserializes into object form then deserializes to xml then serializes to object form then deserializes to original json`() {
        for (test in getTests()) {
            //json
            val jsonPayload = test.jsonSerialization

            //object
            val jsonDeserializer = JsonDeserializer(jsonPayload.encodeToByteArray())
            val bst = test.deserialize(jsonDeserializer)

            //xml
            val xmlSerializer = XmlSerializer()
            bst.serialize(xmlSerializer)
            val xmlPayload = xmlSerializer.toByteArray().decodeToString()

            //object
            val xmlDeserializer = XmlDeserializer(xmlPayload.encodeToByteArray())
            val bst2 = test.deserialize(xmlDeserializer)

            assertEquals(bst, bst2)

            //json - compare
            val jsonSerializer = JsonSerializer()
            bst2.serialize(jsonSerializer)
            val jsonPayload2 = jsonSerializer.toByteArray().decodeToString()

            assertEquals(jsonPayload, jsonPayload2)
        }
    }

    @Test
    fun `object form serializes into equivalent representations in json and xml`() {
        for (test in getTests()) {
            val bst = test.sdkSerializable

            val xmlSerializer = XmlSerializer()
            bst.serialize(xmlSerializer)
            val xml = xmlSerializer.toByteArray().decodeToString()

            val jsonSerializer = JsonSerializer()
            bst.serialize(jsonSerializer)
            val json = jsonSerializer.toByteArray().decodeToString()

            val jsonPayload = test.jsonSerialization
            val xmlPayload = test.xmlSerialization

            assertEquals(xml, xmlPayload)
            assertEquals(json, jsonPayload)
        }
    }

    @Test
    fun `equivalent json and xml serial forms produce the same object form`() {
        for (test in getTests()) {
            val jsonDeserializer = JsonDeserializer(test.jsonSerialization.encodeToByteArray())
            val jsonBst = test.deserialize(jsonDeserializer)

            val xmlDeserializer = XmlDeserializer(test.xmlSerialization.encodeToByteArray())
            val xmlBst = test.deserialize(xmlDeserializer)

            assertEquals(jsonBst, xmlBst)
        }
    }

    @Test
    fun `it deserializes from json and then serializes to xml`() {
        for (test in getTests()) {
            val jsonDeserializer = JsonDeserializer(test.jsonSerialization.encodeToByteArray())
            val bst = test.deserialize(jsonDeserializer)

            val xmlSerializer = XmlSerializer()
            bst.serialize(xmlSerializer)

            assertEquals(test.xmlSerialization, xmlSerializer.toByteArray().decodeToString())
        }
    }

    interface CrossProtocolSerdeTest {
        val jsonSerialization: String
        val xmlSerialization: String
        val sdkSerializable: SdkSerializable
        fun deserialize(deserializer: Deserializer): SdkSerializable
    }

    companion object {
        fun getTests(): List<CrossProtocolSerdeTest> = listOf(BasicStructTest(), ListTest())
    }

    data class BasicStructTest(var x: Int? = null, var y: String? = null, var z: Boolean? = null) : SdkSerializable,
        CrossProtocolSerdeTest {

        companion object {
            val X_DESCRIPTOR = SdkFieldDescriptor("x", SerialKind.Integer)
            val Y_DESCRIPTOR = SdkFieldDescriptor("y", SerialKind.String)
            val Z_DESCRIPTOR = SdkFieldDescriptor("z", SerialKind.Boolean)
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
                serialName = "payload"
                field(X_DESCRIPTOR)
                field(Y_DESCRIPTOR)
                field(Z_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): BasicStructTest {
                val result = BasicStructTest()
                deserializer.deserializeStruct(OBJ_DESCRIPTOR) {
                    loop@ while (true) {
                        when (findNextFieldIndex()) {
                            X_DESCRIPTOR.index -> result.x = deserializeInt()
                            Y_DESCRIPTOR.index -> result.y = deserializeString()
                            Z_DESCRIPTOR.index -> result.z = deserializeBool()
                            null -> break@loop
                            else -> throw RuntimeException("unexpected field in BasicStructTest deserializer")
                        }
                    }
                }
                return result
            }
        }

        override fun serialize(serializer: Serializer) {
            serializer.serializeStruct(OBJ_DESCRIPTOR) {
                field(X_DESCRIPTOR, x!!)
                field(Y_DESCRIPTOR, y!!)
                field(Z_DESCRIPTOR, z!!)
            }
        }

        override val jsonSerialization: String
            get() = """{"x":1,"y":"two","z":true}"""
        override val xmlSerialization: String
            get() = "<payload><x>1</x><y>two</y><z>true</z></payload>"
        override val sdkSerializable: SdkSerializable
            get() = BasicStructTest(1, "two", true)

        override fun deserialize(deserializer: Deserializer): SdkSerializable =
            BasicStructTest.deserialize(deserializer)
    }

    data class ListTest(var intList: List<Int>? = null) : SdkSerializable, CrossProtocolSerdeTest {
        companion object {
            val LIST_DESCRIPTOR = SdkFieldDescriptor("list", SerialKind.List, 0, XmlList())
            val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
                serialName = "payload"
                field(LIST_DESCRIPTOR)
            }

            fun deserialize(deserializer: Deserializer): ListTest {
                val result = ListTest()
                deserializer.deserializeStruct(OBJ_DESCRIPTOR) {
                    loop@ while (true) {
                        when (findNextFieldIndex()) {
                            LIST_DESCRIPTOR.index -> result.intList = deserializer.deserializeList(LIST_DESCRIPTOR) {
                                val intList = mutableListOf<Int>()
                                while (this.hasNextElement()) {
                                    intList.add(this.deserializeInt())
                                }
                                result.intList = intList
                                return@deserializeList intList
                            }
                            null -> break@loop
                            else -> throw RuntimeException("unexpected field in BasicStructTest deserializer")
                        }
                    }
                }
                return result
            }
        }

        override fun serialize(serializer: Serializer) {
            serializer.serializeStruct(OBJ_DESCRIPTOR) {
                listField(LIST_DESCRIPTOR) {
                    for (value in intList!!) {
                        serializeInt(value)
                    }
                }
            }
        }

        override val jsonSerialization: String
            get() = """{"list":[1,2,3,10]}"""
        override val xmlSerialization: String
            get() = "<payload><list><element>1</element><element>2</element><element>3</element><element>10</element></list></payload>"
        override val sdkSerializable: SdkSerializable
            get() = ListTest(listOf(1, 2, 3, 10))

        override fun deserialize(deserializer: Deserializer): SdkSerializable =
            ListTest.deserialize(deserializer)
    }
}