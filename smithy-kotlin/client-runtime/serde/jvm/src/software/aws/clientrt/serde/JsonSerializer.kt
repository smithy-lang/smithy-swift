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
package software.aws.clientrt.serde

import software.aws.clientrt.serde.json.JsonStreamWriter

class JsonSerializer : Serializer, ListSerializer, MapSerializer, StructSerializer {

    val jsonWriter = JsonStreamWriter()

    override fun beginStructure(descriptor: SdkFieldDescriptor): StructSerializer {
        if (descriptor.writeFieldName) {
            jsonWriter.writeName(descriptor.serialName)
        }
        jsonWriter.beginObject()
        return this
    }

    override fun beginList(descriptor: SdkFieldDescriptor): ListSerializer {
        if (descriptor.writeFieldName) {
            jsonWriter.writeName(descriptor.serialName)
        }
        jsonWriter.beginArray()
        return this
    }

    override fun beginMap(descriptor: SdkFieldDescriptor): MapSerializer {
        if (descriptor.writeFieldName) {
            jsonWriter.writeName(descriptor.serialName)
        }
        jsonWriter.beginObject()
        return this
    }

    override fun endStructure() {
        jsonWriter.endObject()
    }

    override fun endList() {
        jsonWriter.endArray()
    }

    override fun endMap() {
        jsonWriter.endObject()
    }

    override fun field(descriptor: SdkFieldDescriptor, value: SdkSerializable) {
        jsonWriter.writeName(descriptor.serialName)
        value.serialize(this)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Int) {
        jsonWriter.writeName(descriptor.serialName)
        serializeInt(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Long) {
        jsonWriter.writeName(descriptor.serialName)
        serializeLong(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Float) {
        jsonWriter.writeName(descriptor.serialName)
        serializeFloat(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: String) {
        jsonWriter.writeName(descriptor.serialName)
        serializeString(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Double) {
        jsonWriter.writeName(descriptor.serialName)
        serializeDouble(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Boolean) {
        jsonWriter.writeName(descriptor.serialName)
        serializeBoolean(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Byte) {
        jsonWriter.writeName(descriptor.serialName)
        serializeByte(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Short) {
        jsonWriter.writeName(descriptor.serialName)
        serializeShort(value)
    }

    override fun field(descriptor: SdkFieldDescriptor, value: Char) {
        jsonWriter.writeName(descriptor.serialName)
        serializeChar(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Int) {
        jsonWriter.writeName(descriptor.serialName)
        serializeInt(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Long) {
        jsonWriter.writeName(descriptor.serialName)
        serializeLong(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Float) {
        jsonWriter.writeName(descriptor.serialName)
        serializeFloat(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: String) {
        jsonWriter.writeName(descriptor.serialName)
        serializeString(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: SdkSerializable) {
        jsonWriter.writeName(descriptor.serialName)
        value.serialize(this)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Double) {
        jsonWriter.writeName(descriptor.serialName)
        serializeDouble(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Boolean) {
        jsonWriter.writeName(descriptor.serialName)
        serializeBoolean(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Byte) {
        jsonWriter.writeName(descriptor.serialName)
        serializeByte(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Short) {
        jsonWriter.writeName(descriptor.serialName)
        serializeShort(value)
    }

    override fun pair(descriptor: SdkFieldDescriptor, value: Char) {
        jsonWriter.writeName(descriptor.serialName)
        serializeChar(value)
    }

    override fun serializeNull(descriptor: SdkFieldDescriptor) {
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
