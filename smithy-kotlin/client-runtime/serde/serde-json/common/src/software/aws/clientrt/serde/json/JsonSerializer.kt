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
package software.aws.clientrt.serde.json

import software.aws.clientrt.serde.*

class JsonSerializer : Serializer, ListSerializer, MapSerializer, StructSerializer {

    private val jsonWriter = jsonStreamWriter()

    override fun toByteArray(): ByteArray {
        return jsonWriter.bytes ?: throw SerializationException("Serializer payload is empty")
    }

    override fun beginStruct(name: String?): StructSerializer {
        jsonWriter.beginObject()
        return this
    }

    override fun beginList(name: String?): ListSerializer {
        jsonWriter.beginArray()
        return this
    }

    override fun beginMap(name: String?): MapSerializer {
        jsonWriter.beginObject()
        return this
    }

    override fun endStruct(name: String?) {
        jsonWriter.endObject()
    }

    override fun endList(name: String?) {
        jsonWriter.endArray()
    }

    override fun endMap(name: String?) {
        jsonWriter.endObject()
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: SdkSerializable) {
        jsonWriter.writeName(descriptor.serialName)
        value.serialize(this)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Int) {
        jsonWriter.writeName(descriptor.serialName)
        serializeInt(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Long) {
        jsonWriter.writeName(descriptor.serialName)
        serializeLong(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Float) {
        jsonWriter.writeName(descriptor.serialName)
        serializeFloat(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: String) {
        jsonWriter.writeName(descriptor.serialName)
        serializeString(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Double) {
        jsonWriter.writeName(descriptor.serialName)
        serializeDouble(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Boolean) {
        jsonWriter.writeName(descriptor.serialName)
        serializeBoolean(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Byte) {
        jsonWriter.writeName(descriptor.serialName)
        serializeByte(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Short) {
        jsonWriter.writeName(descriptor.serialName)
        serializeShort(value)
    }

    override fun field(descriptor: SdkNamedFieldDescriptor, value: Char) {
        jsonWriter.writeName(descriptor.serialName)
        serializeChar(value)
    }

    override fun structField(descriptor: SdkNamedFieldDescriptor, block: StructSerializer.() -> Unit) {
        jsonWriter.writeName(descriptor.serialName)
        serializeStruct(block)
    }

    override fun listField(descriptor: SdkNamedFieldDescriptor, block: ListSerializer.() -> Unit) {
        jsonWriter.writeName(descriptor.serialName)
        serializeList(block)
    }

    override fun mapField(descriptor: SdkNamedFieldDescriptor, block: MapSerializer.() -> Unit) {
        jsonWriter.writeName(descriptor.serialName)
        serializeMap(block)
    }

    override fun entry(key: String, value: Int) {
        jsonWriter.writeName(key)
        serializeInt(value)
    }

    override fun entry(key: String, value: Long) {
        jsonWriter.writeName(key)
        serializeLong(value)
    }

    override fun entry(key: String, value: Float) {
        jsonWriter.writeName(key)
        serializeFloat(value)
    }

    override fun entry(key: String, value: String) {
        jsonWriter.writeName(key)
        serializeString(value)
    }

    override fun entry(key: String, value: SdkSerializable) {
        jsonWriter.writeName(key)
        value.serialize(this)
    }

    override fun entry(key: String, value: Double) {
        jsonWriter.writeName(key)
        serializeDouble(value)
    }

    override fun entry(key: String, value: Boolean) {
        jsonWriter.writeName(key)
        serializeBoolean(value)
    }

    override fun entry(key: String, value: Byte) {
        jsonWriter.writeName(key)
        serializeByte(value)
    }

    override fun entry(key: String, value: Short) {
        jsonWriter.writeName(key)
        serializeShort(value)
    }

    override fun entry(key: String, value: Char) {
        jsonWriter.writeName(key)
        serializeChar(value)
    }

    override fun serializeNull(descriptor: SdkNamedFieldDescriptor) {
        jsonWriter.writeName(descriptor.serialName)
        jsonWriter.writeNull()
    }

    override fun serializeBoolean(value: Boolean) {
        jsonWriter.writeValue(value)
    }

    override fun serializeByte(value: Byte) {
        jsonWriter.writeValue(value)
    }

    override fun serializeShort(value: Short) {
        jsonWriter.writeValue(value)
    }

    override fun serializeChar(value: Char) {
        jsonWriter.writeValue(value.toString())
    }

    override fun serializeInt(value: Int) {
        jsonWriter.writeValue(value)
    }

    override fun serializeLong(value: Long) {
        jsonWriter.writeValue(value)
    }

    override fun serializeFloat(value: Float) {
        jsonWriter.writeValue(value)
    }

    override fun serializeDouble(value: Double) {
        jsonWriter.writeValue(value)
    }

    override fun serializeString(value: String) {
        jsonWriter.writeValue(value)
    }

    override fun serializeSdkSerializable(value: SdkSerializable) {
        value.serialize(this)
    }
}
