/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import software.aws.clientrt.serde.*

class XmlDeserializer2(private val reader: XmlStreamReader) : Deserializer {
    constructor(input: ByteArray) : this(xmlStreamReader(input))

    override fun deserializeStruct(descriptor: SdkFieldDescriptor?): Deserializer.FieldIterator {
        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        return StructFieldIterator(this, reader.currentDepth(), reader, beginNode)
    }

    override fun deserializeList(descriptor: SdkFieldDescriptor?): Deserializer.ElementIterator {
        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        return ListFieldIterator(this, reader.currentDepth(), reader, beginNode)
    }

    override fun deserializeMap(descriptor: SdkFieldDescriptor?): Deserializer.EntryIterator {
        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        return MapFieldIterator(this, reader.currentDepth(), reader, beginNode)
    }

    override fun deserializeByte(descriptor: SdkFieldDescriptor?): Byte = deserializePrimitive(descriptor) { it.toByteOrNull() }

    override fun deserializeInt(descriptor: SdkFieldDescriptor?): Int = deserializePrimitive(descriptor) { it.toIntOrNull() }

    override fun deserializeShort(descriptor: SdkFieldDescriptor?): Short = deserializePrimitive(descriptor) { it.toShortOrNull() }

    override fun deserializeLong(descriptor: SdkFieldDescriptor?): Long = deserializePrimitive(descriptor) { it.toLongOrNull() }

    override fun deserializeFloat(descriptor: SdkFieldDescriptor?): Float = deserializePrimitive(descriptor) { it.toFloatOrNull() }

    override fun deserializeDouble(descriptor: SdkFieldDescriptor?): Double = deserializePrimitive(descriptor) { it.toDoubleOrNull() }

    override fun deserializeString(descriptor: SdkFieldDescriptor?): String = deserializePrimitive(descriptor) { it }

    override fun deserializeBool(descriptor: SdkFieldDescriptor?): Boolean  = deserializePrimitive(descriptor) { it.toBoolean() }

    private fun <T> deserializePrimitive(descriptor: SdkFieldDescriptor?, transform: (String) -> T?): T {
        requireNotNull(descriptor) { "Must provide a non-null value for elementName." }
        require(descriptor is XmlFieldDescriptor)

        val node = reader.nextTokenOf<XmlToken.BeginElement>()

        require(node.name == descriptor.nodeName) { "Expected '${descriptor.nodeName}' but got '${node.name}' instead."}

        val rt = reader.nextTokenOf<XmlToken.Text>()

        val rv = rt.value ?: throw IllegalStateException("Expected value but text of element was empty.")
        requireToken<XmlToken.EndElement>(reader.nextToken())

        return transform(rv) ?: throw IllegalArgumentException("Cannot parse $rv with ${transform::class}")
    }
}

class MapFieldIterator(
    private val deserializer: Deserializer,
    private val depth: Int,
    private val reader: XmlStreamReader,
    private val beginNode: XmlToken.BeginElement
) : Deserializer.EntryIterator {

    override fun next(): Int {
        require(reader.currentDepth() >= depth) { "Traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> Deserializer.ElementIterator.EXHAUSTED
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nt.name == beginNode.name) {
                    Deserializer.ElementIterator.EXHAUSTED
                } else {
                    reader.nextTokenOf<XmlToken.EndElement>() // Consume terminating node of child
                    next() //Recurse
                }
            else -> 0
        }
    }

    override fun key(descriptor: SdkFieldDescriptor?): String = deserializeString(descriptor)

    override fun deserializeByte(descriptor: SdkFieldDescriptor?): Byte = deserializer.deserializeByte(descriptor)

    override fun deserializeInt(descriptor: SdkFieldDescriptor?): Int = deserializer.deserializeInt(descriptor)

    override fun deserializeShort(descriptor: SdkFieldDescriptor?): Short = deserializer.deserializeShort(descriptor)

    override fun deserializeLong(descriptor: SdkFieldDescriptor?): Long = deserializer.deserializeLong(descriptor)

    override fun deserializeFloat(descriptor: SdkFieldDescriptor?): Float = deserializer.deserializeFloat(descriptor)

    override fun deserializeDouble(descriptor: SdkFieldDescriptor?): Double = deserializer.deserializeDouble(descriptor)

    override fun deserializeString(descriptor: SdkFieldDescriptor?): String = deserializer.deserializeString(descriptor)

    override fun deserializeBool(descriptor: SdkFieldDescriptor?): Boolean = deserializer.deserializeBool(descriptor)
}

class ListFieldIterator(
    private val deserializer: XmlDeserializer2,
    private val depth: Int,
    private val reader: XmlStreamReader,
    private val beginNode: XmlToken.BeginElement
) : Deserializer.ElementIterator {

    override fun next(): Int {
        require(reader.currentDepth() >= depth) { "Traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> Deserializer.ElementIterator.EXHAUSTED
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nt.name == beginNode.name) {
                    Deserializer.ElementIterator.EXHAUSTED
                } else {
                    reader.nextTokenOf<XmlToken.EndElement>() // Consume terminating node of child
                    next() //Recurse
                }
            else -> 0
        }
    }

    override fun deserializeByte(descriptor: SdkFieldDescriptor?): Byte = deserializer.deserializeByte(descriptor)

    override fun deserializeInt(descriptor: SdkFieldDescriptor?): Int = deserializer.deserializeInt(descriptor)

    override fun deserializeShort(descriptor: SdkFieldDescriptor?): Short = deserializer.deserializeShort(descriptor)

    override fun deserializeLong(descriptor: SdkFieldDescriptor?): Long = deserializer.deserializeLong(descriptor)

    override fun deserializeFloat(descriptor: SdkFieldDescriptor?): Float = deserializer.deserializeFloat(descriptor)

    override fun deserializeDouble(descriptor: SdkFieldDescriptor?): Double = deserializer.deserializeDouble(descriptor)

    override fun deserializeString(descriptor: SdkFieldDescriptor?): String = deserializer.deserializeString(descriptor)

    override fun deserializeBool(descriptor: SdkFieldDescriptor?): Boolean = deserializer.deserializeBool(descriptor)
}

class StructFieldIterator(
    private val deserializer: Deserializer,
    private val depth: Int,
    private val reader: XmlStreamReader,
    private val structNode: XmlToken.BeginElement
) : Deserializer.FieldIterator {

    override fun nextField(descriptor: SdkObjectDescriptor): Int {
        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> Deserializer.FieldIterator.EXHAUSTED
            is XmlToken.EndElement -> {
                // consume the token
                val endToken = reader.nextTokenOf<XmlToken.EndElement>()

                if (reader.currentDepth() == depth && endToken.name == structNode.name) {
                    Deserializer.FieldIterator.EXHAUSTED
                } else {
                    nextField(descriptor) //Recurse
                }
            }
            is XmlToken.BeginElement -> {
                val propertyName = nt.name
                //FIXME: The following filter needs to take XML namespace into account when matching.
                val field = descriptor.fields.filterIsInstance<XmlFieldDescriptor>().find { it.nodeName == propertyName }
                field?.index ?: Deserializer.FieldIterator.UNKNOWN_FIELD
            }
            else -> throw IllegalArgumentException("Unexpected token $nt")
        }
    }

    override fun skipValue() = reader.skipNext()

    override fun deserializeByte(descriptor: SdkFieldDescriptor?): Byte = deserializer.deserializeByte(descriptor)

    override fun deserializeInt(descriptor: SdkFieldDescriptor?): Int = deserializer.deserializeInt(descriptor)

    override fun deserializeShort(descriptor: SdkFieldDescriptor?): Short = deserializer.deserializeShort(descriptor)

    override fun deserializeLong(descriptor: SdkFieldDescriptor?): Long = deserializer.deserializeLong(descriptor)

    override fun deserializeFloat(descriptor: SdkFieldDescriptor?): Float = deserializer.deserializeFloat(descriptor)

    override fun deserializeDouble(descriptor: SdkFieldDescriptor?): Double = deserializer.deserializeDouble(descriptor)

    override fun deserializeString(descriptor: SdkFieldDescriptor?): String = deserializer.deserializeString(descriptor)

    override fun deserializeBool(descriptor: SdkFieldDescriptor?): Boolean = deserializer.deserializeBool(descriptor)
}

// return the next token and require that it be of type [TExpected] or else throw an exception
private inline fun <reified TExpected : XmlToken> XmlStreamReader.nextTokenOf(): TExpected {
    val token = this.nextToken()
    requireToken<TExpected>(token)
    return token as TExpected
}

// require that the given token be of type [TExpected] or else throw an exception
private inline fun <reified TExpected> requireToken(token: XmlToken) {
    if (token::class != TExpected::class) {
        throw DeserializerStateException("expected ${TExpected::class}; found ${token::class}")
    }
}

// Deserializer.ElementIterator, Deserializer.FieldIterator, Deserializer.EntryIterator