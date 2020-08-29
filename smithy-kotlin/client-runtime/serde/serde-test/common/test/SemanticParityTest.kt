import software.aws.clientrt.serde.*
import software.aws.clientrt.serde.json.JsonDeserializer
import software.aws.clientrt.serde.xml.XmlSerializer
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

@ExperimentalStdlibApi
class SemanticParityTest {

    @Test
    fun `it deserializes from json and then serializes to xml`() {
        val jsonPayload = """{"x":1,"y":"two","z":true}"""
        val xmlPayload = "<payload><x>1</x><y>two</y><z>true</z></payload>"

        val jsonDeserializer = JsonDeserializer(jsonPayload.encodeToByteArray())
        val bst = BasicStructTest.deserialize(jsonDeserializer)

        val xmlSerializer = XmlSerializer()
        bst.serialize(xmlSerializer)

        assertEquals(xmlPayload, xmlSerializer.toByteArray().decodeToString())
    }

    class BasicStructTest : SdkSerializable {
        var x: Int? = null
        var y: String? = null
        var z: Boolean? = null

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
    }
}