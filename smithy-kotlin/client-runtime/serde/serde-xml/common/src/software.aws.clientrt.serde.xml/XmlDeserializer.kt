/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor

class XmlDeserializer(payload: ByteArray) : Deserializer, Deserializer.ElementIterator, Deserializer.FieldIterator, Deserializer.EntryIterator {

    init {

    }

    override fun deserializeStruct(descriptor: SdkFieldDescriptor?): Deserializer.FieldIterator {
        TODO("Not yet implemented")
    }

    override fun deserializeList(): Deserializer.ElementIterator {
        TODO("Not yet implemented")
    }

    override fun deserializeMap(): Deserializer.EntryIterator {
        TODO("Not yet implemented")
    }

    override fun next(): Int {
        TODO("Not yet implemented")
    }

    override fun key(): String {
        TODO("Not yet implemented")
    }

    override fun deserializeByte(): Byte {
        TODO("Not yet implemented")
    }

    override fun deserializeInt(): Int {
        TODO("Not yet implemented")
    }

    override fun deserializeShort(): Short {
        TODO("Not yet implemented")
    }

    override fun deserializeLong(): Long {
        TODO("Not yet implemented")
    }

    override fun deserializeFloat(): Float {
        TODO("Not yet implemented")
    }

    override fun deserializeDouble(): Double {
        TODO("Not yet implemented")
    }

    override fun deserializeString(): String {
        TODO("Not yet implemented")
    }

    override fun deserializeBool(): Boolean {
        TODO("Not yet implemented")
    }

    override fun nextField(descriptor: SdkObjectDescriptor): Int {
        TODO("Not yet implemented")
    }

    override fun skipValue() {
        TODO("Not yet implemented")
    }

}