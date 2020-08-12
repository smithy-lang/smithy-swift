/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import software.aws.clientrt.serde.*

/**
 * A deserializer for XML encoded data.
 */
class XmlDeserializer(private val reader: XmlStreamReader) : Deserializer {
    constructor(input: ByteArray) : this(xmlStreamReader(input))

    /**
     * Deserialize an element with children of arbitrary values.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the struct values.
     */
    override fun deserializeStruct(descriptor: SdkFieldDescriptor?): Deserializer.FieldIterator {
        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        return CompositeIterator(this, reader.currentDepth(), reader, beginNode)
    }

    /**
     * Deserialize an element with identically-typed children.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the list values.
     */
    override fun deserializeList(descriptor: SdkFieldDescriptor?): Deserializer.ElementIterator {
        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        return CompositeIterator(this, reader.currentDepth(), reader, beginNode)
    }

    /**
     * Deserialize an element with identically-typed children of key/value pairs.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the list values.
     */
    override fun deserializeMap(descriptor: SdkFieldDescriptor?): Deserializer.EntryIterator {
        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        return CompositeIterator(this, reader.currentDepth(), reader, beginNode)
    }

    /**
     * Deserialize a byte value defined as the text section of an Xml element.
     *
     */
    override fun deserializeByte(): Byte =
        deserializePrimitive { it.toByteOrNull() }

    /**
     * Deserialize an integer value defined as the text section of an Xml element.
     */
    override fun deserializeInt(): Int =
        deserializePrimitive { it.toIntOrNull() }

    /**
     * Deserialize a short value defined as the text section of an Xml element.
     */
    override fun deserializeShort(): Short =
        deserializePrimitive { it.toShortOrNull() }

    /**
     * Deserialize a long value defined as the text section of an Xml element.
     */
    override fun deserializeLong(): Long =
        deserializePrimitive { it.toLongOrNull() }

    /**
     * Deserialize an float value defined as the text section of an Xml element.
     */
    override fun deserializeFloat(): Float =
        deserializePrimitive { it.toFloatOrNull() }

    /**
     * Deserialize a double value defined as the text section of an Xml element.
     */
    override fun deserializeDouble(): Double =
        deserializePrimitive { it.toDoubleOrNull() }

    /**
     * Deserialize an integer value defined as the text section of an Xml element.
     */
    override fun deserializeString(): String = deserializePrimitive { it }

    /**
     * Deserialize an integer value defined as the text section of an Xml element.
     */
    override fun deserializeBool(): Boolean =
        deserializePrimitive { it.toBoolean() }

    private fun <T> deserializePrimitive(transform: (String) -> T?): T {
        val rt = reader.nextTokenOf<XmlToken.Text>()

        val rv = rt.value ?: throw DeserializationException("Expected value but text of element was null.")
        return transform(rv) ?: throw DeserializationException("Cannot parse $rv with ${transform::class}")
    }
}

/**
 * Captures state and implements interfaces necessary to deserialize Field, Entry, and Elements.
 */
private class CompositeIterator(
    private val deserializer: Deserializer,
    private val depth: Int,
    private val reader: XmlStreamReader,
    private val beginNode: XmlToken.BeginElement
) : Deserializer.EntryIterator, Deserializer.ElementIterator, Deserializer.FieldIterator {

    // Deserializer.EntryIterator, Deserializer.ElementIterator
    override fun hasNext(): Boolean {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> false
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nt.name == beginNode.name) {
                    false
                } else {
                    reader.nextTokenOf<XmlToken.EndElement>() // Consume terminating node of child
                    hasNext() // recurse
                }
            else -> true
        }
    }

    // Deserializer.FieldIterator
    override fun findNextFieldIndexOrNull(descriptor: SdkObjectDescriptor): Int? {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> null
            is XmlToken.EndElement -> {
                // consume the token
                val endToken = reader.nextTokenOf<XmlToken.EndElement>()

                if (reader.currentDepth() == depth && endToken.name == beginNode.name) {
                    null
                } else {
                    findNextFieldIndexOrNull(descriptor) // recurse
                }
            }
            is XmlToken.BeginElement -> {
                val propertyName = nt.name
                //FIXME: The following filter needs to take XML namespace into account when matching.
                val field =
                    descriptor.fields.filterIsInstance<XmlFieldDescriptor>().find { it.nodeName == propertyName }
                field?.index ?: Deserializer.FieldIterator.UNKNOWN_FIELD
            }
            else -> throw DeserializationException("Unexpected token $nt")
        }
    }

    // Deserializer.FieldIterator
    override fun skipValue() = reader.skipNext()

    // Deserializer.EntryIterator
    override fun key(descriptor: SdkFieldDescriptor?): String = deserializeString()

    override fun deserializeByte(): Byte = deserializer.deserializeByte()

    override fun deserializeInt(): Int = deserializer.deserializeInt()

    override fun deserializeShort(): Short = deserializer.deserializeShort()

    override fun deserializeLong(): Long = deserializer.deserializeLong()

    override fun deserializeFloat(): Float = deserializer.deserializeFloat()

    override fun deserializeDouble(): Double = deserializer.deserializeDouble()

    override fun deserializeString(): String = deserializer.deserializeString()

    override fun deserializeBool(): Boolean = deserializer.deserializeBool()
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