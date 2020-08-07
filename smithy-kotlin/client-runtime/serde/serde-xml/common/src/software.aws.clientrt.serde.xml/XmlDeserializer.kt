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
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the byte value.
     */
    override fun deserializeByte(descriptor: SdkFieldDescriptor?): Byte =
        deserializePrimitive(descriptor) { it.toByteOrNull() }

    /**
     * Deserialize an integer value defined as the text section of an Xml element.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the integer value.
     */
    override fun deserializeInt(descriptor: SdkFieldDescriptor?): Int =
        deserializePrimitive(descriptor) { it.toIntOrNull() }

    /**
     * Deserialize a short value defined as the text section of an Xml element.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the short value.
     */
    override fun deserializeShort(descriptor: SdkFieldDescriptor?): Short =
        deserializePrimitive(descriptor) { it.toShortOrNull() }

    /**
     * Deserialize a long value defined as the text section of an Xml element.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the long value.
     */
    override fun deserializeLong(descriptor: SdkFieldDescriptor?): Long =
        deserializePrimitive(descriptor) { it.toLongOrNull() }

    /**
     * Deserialize an float value defined as the text section of an Xml element.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the float value.
     */
    override fun deserializeFloat(descriptor: SdkFieldDescriptor?): Float =
        deserializePrimitive(descriptor) { it.toFloatOrNull() }

    /**
     * Deserialize a double value defined as the text section of an Xml element.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the double value.
     */
    override fun deserializeDouble(descriptor: SdkFieldDescriptor?): Double =
        deserializePrimitive(descriptor) { it.toDoubleOrNull() }

    /**
     * Deserialize an integer value defined as the text section of an Xml element.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the integer value.
     */
    override fun deserializeString(descriptor: SdkFieldDescriptor?): String = deserializePrimitive(descriptor) { it }

    /**
     * Deserialize an integer value defined as the text section of an Xml element.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the integer value.
     */
    override fun deserializeBool(descriptor: SdkFieldDescriptor?): Boolean =
        deserializePrimitive(descriptor) { it.toBoolean() }

    private fun <T> deserializePrimitive(descriptor: SdkFieldDescriptor?, transform: (String) -> T?): T {
        requireNotNull(descriptor) { "Must provide a non-null value for elementName." }
        require(descriptor is XmlFieldDescriptor)

        val node = reader.nextTokenOf<XmlToken.BeginElement>()

        require(node.name == descriptor.nodeName) { "Expected '${descriptor.nodeName}' but got '${node.name}' instead." }

        val rt = reader.nextTokenOf<XmlToken.Text>()

        val rv = rt.value ?: throw DeserializationException("Expected value but text of element was empty.")
        requireToken<XmlToken.EndElement>(reader.nextToken()) // consume the end node

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