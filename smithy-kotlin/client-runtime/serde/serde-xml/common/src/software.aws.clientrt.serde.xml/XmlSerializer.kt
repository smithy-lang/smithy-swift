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

class XmlSerializer(private val xmlWriter: XmlStreamWriter = xmlStreamWriter()) : Serializer, ListSerializer, MapSerializer, StructSerializer {

    override fun toByteArray(): ByteArray {
        return xmlWriter.bytes
    }

    override fun beginStruct(name: String?): StructSerializer {
        xmlWriter.startTag(name ?: throw XmlGenerationException(IllegalArgumentException("Must specify a struct name for XML.")))
        return this
    }

    override fun beginList(name: String?): ListSerializer {
        xmlWriter.startTag(name ?: throw XmlGenerationException(IllegalArgumentException("Must specify a struct name for XML.")))
        return this
    }

    override fun beginMap(name: String?): MapSerializer {
        xmlWriter.startTag(name ?: throw XmlGenerationException(IllegalArgumentException("Must specify a struct name for XML.")))
        return this
    }

    override fun endStruct(name: String?) {
       xmlWriter.endTag(name ?: throw XmlGenerationException(IllegalArgumentException("Must specify a struct name for XML.")))
    }

    override fun endList(name: String?) {
        xmlWriter.endTag(name ?: throw XmlGenerationException(IllegalArgumentException("Must specify a struct name for XML.")))
    }

    override fun endMap(name: String?) {
        xmlWriter.endTag(name ?: throw XmlGenerationException(IllegalArgumentException("Must specify a struct name for XML.")))
    }

    override fun field(descriptor: JsonFieldDescriptor, value: SdkSerializable) = value.serialize(this)

    override fun field(descriptor: JsonFieldDescriptor, value: Int) {
        xmlWriter.startTag(descriptor.serialName)
        serializeInt(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: Long) {
        xmlWriter.startTag(descriptor.serialName)
        serializeLong(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: Float) {
        xmlWriter.startTag(descriptor.serialName)
        serializeFloat(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: String) {
        xmlWriter.startTag(descriptor.serialName)
        serializeString(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: Double) {
        xmlWriter.startTag(descriptor.serialName)
        serializeDouble(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: Boolean) {
        xmlWriter.startTag(descriptor.serialName)
        serializeBoolean(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: Byte) {
        xmlWriter.startTag(descriptor.serialName)
        serializeByte(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: Short) {
        xmlWriter.startTag(descriptor.serialName)
        serializeShort(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun field(descriptor: JsonFieldDescriptor, value: Char) {
        xmlWriter.startTag(descriptor.serialName)
        serializeChar(value)
        xmlWriter.endTag(descriptor.serialName)
    }

    override fun structField(descriptor: JsonFieldDescriptor, block: StructSerializer.() -> Unit) = serializeStruct(descriptor.serialName, block)

    override fun listField(descriptor: JsonFieldDescriptor, block: ListSerializer.() -> Unit) = serializeList(descriptor.serialName, block)

    override fun mapField(descriptor: JsonFieldDescriptor, block: MapSerializer.() -> Unit) = serializeMap(descriptor.serialName, block)

    override fun entry(key: String, value: Int) {
        xmlWriter.startTag(key)
        serializeInt(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: Long) {
        xmlWriter.startTag(key)
        serializeLong(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: Float) {
        xmlWriter.startTag(key)
        serializeFloat(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: String) {
        xmlWriter.startTag(key)
        serializeString(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: SdkSerializable) {
        xmlWriter.startTag(key)
        value.serialize(this)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: Double) {
        xmlWriter.startTag(key)
        serializeDouble(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: Boolean) {
        xmlWriter.startTag(key)
        serializeBoolean(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: Byte) {
        xmlWriter.startTag(key)
        serializeByte(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: Short) {
        xmlWriter.startTag(key)
        serializeShort(value)
        xmlWriter.endTag(key)
    }

    override fun entry(key: String, value: Char) {
        xmlWriter.startTag(key)
        serializeChar(value)
        xmlWriter.endTag(key)
    }

    override fun serializeNull(descriptor: JsonFieldDescriptor) {
        // This might also be represented w/ attrib 'xsi:nil="true"'
        TODO("Unsure of how to handle this atm.")
    }

    override fun serializeBoolean(value: Boolean) = xmlWriter.text(value)

    override fun serializeByte(value: Byte) = xmlWriter.text(value)

    override fun serializeShort(value: Short) = xmlWriter.text(value)

    override fun serializeChar(value: Char) {
        xmlWriter.text(value.toString())
    }

    override fun serializeInt(value: Int) = xmlWriter.text(value)

    override fun serializeLong(value: Long) = xmlWriter.text(value)

    override fun serializeFloat(value: Float) = xmlWriter.text(value)

    override fun serializeDouble(value: Double) = xmlWriter.text(value)

    override fun serializeString(value: String) {
        xmlWriter.text(value)
    }

    override fun serializeSdkSerializable(value: SdkSerializable) = value.serialize(this)
}
