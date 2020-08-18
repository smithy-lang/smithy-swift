/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import software.aws.clientrt.serde.*

/**
 * A deserializer for XML encoded data.
 *
 * This class implements interfaces that support a variety of serialization formats.  There
 * is not an explicit end-tag consumption operation provided by these interfaces.  This implementation
 * consumes end tokens by checking for them each time a new token is to be consumed.  If the next
 * token in this case is an end token, it is consumed and discarded.
 */
class XmlDeserializer(private val reader: XmlStreamReader) : Deserializer {
    constructor(input: ByteArray) : this(xmlStreamReader(input))

    /**
     * Deserialize an element with children of arbitrary values.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the struct values.
     */
    override fun deserializeStruct(descriptor: SdkFieldDescriptor): Deserializer.FieldIterator {
        require(descriptor is SdkNamedFieldDescriptor) { "Expected SdkNamedFieldDescriptor but got ${descriptor::class}" }
        reader.consumeEndToken()

        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        return CompositeIterator(this, reader.currentDepth(), reader, beginNode, descriptor)
    }

    /**
     * Deserialize an element with identically-typed children.
     */
    override fun deserializeList(descriptor: SdkFieldDescriptor): Deserializer.ElementIterator {
        require(descriptor is SdkNamedFieldDescriptor) { "Expected SdkNamedFieldDescriptor but got ${descriptor::class}" }
        reader.consumeEndToken()

        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        require(descriptor.serialName == beginNode.name) { "Expected list start tag of ${beginNode.name} but got ${descriptor.serialName}" }

        return CompositeIterator(this, reader.currentDepth(), reader, beginNode, descriptor)
    }

    /**
     * Deserialize an element with identically-typed children of key/value pairs.
     */
    override fun deserializeMap(descriptor: SdkFieldDescriptor): Deserializer.EntryIterator {
        require(descriptor is SdkNamedFieldDescriptor) { "Expected SdkNamedFieldDescriptor but got ${descriptor::class}" }
        reader.consumeEndToken()

        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>() //Consume the container start tag
        require(descriptor.serialName == beginNode.name) { "Expected map start tag of ${beginNode.name} but got ${descriptor.serialName}" }

        return CompositeIterator(this, reader.currentDepth(), reader, beginNode, descriptor)
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
    private val beginNode: XmlToken.BeginElement,
    private val descriptor: SdkNamedFieldDescriptor
) : Deserializer.EntryIterator, Deserializer.ElementIterator, Deserializer.FieldIterator {

    private var consumedWrapper = false

    // Deserializer.EntryIterator, Deserializer.ElementIterator
    override fun hasNextElement(): Boolean {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        val nextToken = reader.peek()
        if (nextToken is XmlToken.BeginElement) { // Determine if next node is our wrapper, if so consume.
            require(nextToken.name == getListWrapperName(descriptor)) { "Expected entry wrapper ${descriptor.serialName} but got ${nextToken.name}" }
            // reader.nextTokenOf<XmlToken.BeginElement>()
        }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> false
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nt.name == beginNode.name) {
                    false
                } else {
                    reader.nextTokenOf<XmlToken.EndElement>() // Consume terminating node of child
                    hasNextElement() // recurse
                }
            else -> true
        }
    }

    override fun hasNextEntry(): Boolean {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        var nextToken = reader.peek()
        if (nextToken is XmlToken.BeginElement) { // Determine if next node is our wrapper, if so consume.
            val mapInfo = (descriptor.kind as SerialKind.Map).traits.first { it is XmlMap } as XmlMap
            if (!consumedWrapper && !mapInfo.flattened) {
                require(nextToken.name == getListWrapperName(descriptor)) { "Expected entry wrapper ${descriptor.serialName} but got ${(nextToken as XmlToken.BeginElement).name}" }
                consumedWrapper = true
                nextToken = reader.nextTokenOf<XmlToken.BeginElement>()
                nextToken = reader.peek()
                require(nextToken is XmlToken.BeginElement) { "Expected begin tag but got ${nextToken::class}"}
            }

            require(nextToken.name == mapInfo.entry) { "Expected node named ${mapInfo.entry} but got ${nextToken.name}" }
            reader.nextTokenOf<XmlToken.BeginElement>()
        }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> false
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nt.name == beginNode.name) {
                    false
                } else {
                    reader.nextTokenOf<XmlToken.EndElement>() // Consume terminating node of child
                    hasNextEntry() // recurse
                }
            else -> true
        }
    }

    private fun getListWrapperName(descriptor: SdkNamedFieldDescriptor): String {
        return when(descriptor.kind) {
            is SerialKind.List -> {
                val listInfo = (descriptor.kind as SerialKind.List).traits.first { it is XmlList } as XmlList
                listInfo.elementName
            }
            is SerialKind.Map -> {
                val listInfo = (descriptor.kind as SerialKind.Map).traits.first { it is XmlMap } as XmlMap
                listInfo.parent ?: error("Cannot get wrapper of flattened map.")
            }
            else -> error("Unexpected descriptor kind: ${descriptor.kind::class}")
        }
    }

    // Deserializer.EntryIterator
    override fun key(): String {
        reader.consumeEndToken()

        val key = deserializer.deserializeStruct(descriptor).deserializeString()
        reader.consumeEndToken()

        val valueToken = reader.nextTokenOf<XmlToken.BeginElement>()
        val mapInfo = (descriptor.kind as SerialKind.Map).traits.first { it is XmlMap } as XmlMap
        require(valueToken.name == mapInfo.valueName)

        return key
    }

    // Deserializer.FieldIterator
    override fun findNextFieldIndex(descriptor: SdkObjectDescriptor): Int? {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> null
            is XmlToken.EndElement -> {
                // consume the token
                val endToken = reader.nextTokenOf<XmlToken.EndElement>()

                if (reader.currentDepth() == depth && endToken.name == beginNode.name) {
                    null
                } else {
                    findNextFieldIndex(descriptor) // recurse
                }
            }
            is XmlToken.BeginElement -> {
                val propertyName = nt.name
                //FIXME: The following filter needs to take XML namespace into account when matching.
                val field =
                    descriptor.fields().find { it.serialName == propertyName }
                val rt = field?.index ?: Deserializer.FieldIterator.UNKNOWN_FIELD

                if (shouldConsume2(field)) {
                    reader.nextTokenOf<XmlToken.BeginElement>()
                }

                rt
            }
            else -> throw DeserializationException("Unexpected token $nt")
        }
    }

    private fun shouldConsume2(field: SdkNamedFieldDescriptor?): Boolean {
        // Hacky policy as a way of giving a hint to the deserializer to not consume start token so it can
        // be passed to the nested deserializer.  If works, codify into a specific type SdkNestedObjectDescriptor or something.
        return when {
            field is SdkObjectDescriptor -> false
            field?.kind is SerialKind.List -> false
            field?.kind is SerialKind.Map -> false
            field == null -> false
            else -> true
        }
    }

    // Deserializer.FieldIterator
    override fun skipValue() = reader.skipNext()

    override fun deserializeByte(): Byte {
        reader.consumeEndToken()
        return deserializer.deserializeByte()
    }

    override fun deserializeInt(): Int {
        reader.consumeEndToken()
        reader.consumeListWrapper(descriptor)

        return deserializer.deserializeInt()
    }

    override fun deserializeShort(): Short {
        reader.consumeEndToken()
        reader.consumeListWrapper(descriptor)
        return deserializer.deserializeShort()
    }

    override fun deserializeLong(): Long {
        reader.consumeEndToken()
        reader.consumeListWrapper(descriptor)
        return deserializer.deserializeLong()
    }

    override fun deserializeFloat(): Float {
        reader.consumeEndToken()
        reader.consumeListWrapper(descriptor)
        return deserializer.deserializeFloat()
    }

    override fun deserializeDouble(): Double {
        reader.consumeEndToken()
        reader.consumeListWrapper(descriptor)
        return deserializer.deserializeDouble()
    }

    override fun deserializeString(): String {
        reader.consumeEndToken()
        reader.consumeListWrapper(descriptor)
        return deserializer.deserializeString()
    }

    override fun deserializeBool(): Boolean {
        reader.consumeEndToken()
        reader.consumeListWrapper(descriptor)
        return deserializer.deserializeBool()
    }
}

private fun XmlStreamReader.consumeEndToken() {
    if (peek() is XmlToken.EndElement) skipNext()
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

fun XmlStreamReader.consumeListWrapper(descriptor: SdkNamedFieldDescriptor) {
    val nt = this.peek()
    if (nt is XmlToken.BeginElement) {
        val listInfo = (descriptor.kind as SerialKind.List).traits.first { it is XmlList } as XmlList
        require(nt.name == listInfo.elementName) { "Expected ${listInfo.elementName} but found ${nt.name}" }
        this.nextTokenOf<XmlToken.BeginElement>()
    }
}