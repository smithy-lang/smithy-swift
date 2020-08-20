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
class XmlDeserializer(private val reader: XmlStreamReader, private val nodeNameStack: MutableList<String> = mutableListOf()) : Deserializer {
    constructor(input: ByteArray) : this(xmlStreamReader(input))

    /**
     * Deserialize an element with children of arbitrary values.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the struct values.
     */
    override fun deserializeStruct(descriptor: SdkFieldDescriptor): Deserializer.FieldIterator {
        reader.consumeEndToken(nodeNameStack)

        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>(nodeNameStack) //Consume the container start tag

        return CompositeIterator(this, reader.currentDepth(), reader, beginNode, descriptor, nodeNameStack)
    }

    /**
     * Deserialize an element with identically-typed children.
     */
    override fun deserializeList(descriptor: SdkFieldDescriptor): Deserializer.ElementIterator {
        reader.consumeEndToken(nodeNameStack)

        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>(nodeNameStack) //Consume the container start tag
        require(descriptor.serialName == beginNode.name) { "Expected list start tag of ${beginNode.name} but got ${descriptor.serialName}" }

        return CompositeIterator(this, reader.currentDepth(), reader, beginNode, descriptor, nodeNameStack)
    }

    /**
     * Deserialize an element with identically-typed children of key/value pairs.
     */
    override fun deserializeMap(descriptor: SdkFieldDescriptor): Deserializer.EntryIterator {
        reader.consumeEndToken(nodeNameStack)

        val beginNode = reader.nextTokenOf<XmlToken.BeginElement>(nodeNameStack) //Consume the container start tag
        require(descriptor.serialName == beginNode.name) { "Expected map start tag of ${beginNode.name} but got ${descriptor.serialName}" }

        return CompositeIterator(this, reader.currentDepth(), reader, beginNode, descriptor, nodeNameStack)
    }

    /**
     * Deserialize a byte value defined as the text section of an Xml element.
     *
     */
    override fun deserializeByte(): Byte =
        deserializePrimitive { it.toIntOrNull()?.toByte() }

    /**
     * Deserialize an integer value defined as the text section of an Xml element.
     */
    override fun deserializeInt(): Int =
        deserializePrimitive { it.toIntOrNull() }

    /**
     * Deserialize a short value defined as the text section of an Xml element.
     */
    override fun deserializeShort(): Short =
        deserializePrimitive { it.toIntOrNull()?.toShort() }

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
        val rt = reader.nextTokenOf<XmlToken.Text>(nodeNameStack)

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
    private val descriptor: SdkFieldDescriptor,
    private val nodeNameStack: MutableList<String>
) : Deserializer.EntryIterator, Deserializer.ElementIterator, Deserializer.FieldIterator {

    private var consumedWrapper = false

    // Deserializer.EntryIterator, Deserializer.ElementIterator
    override fun hasNextElement(): Boolean {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        val nextToken = reader.peek()
        if (nextToken is XmlToken.BeginElement) { // Determine if next node is our wrapper, if so consume.
            require(nextToken.name == getListWrapperName(descriptor)) { "Expected entry wrapper ${descriptor.serialName} but got ${nextToken.name}" }
        }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> false
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nt.name == beginNode.name) {
                    false
                } else {
                    reader.nextTokenOf<XmlToken.EndElement>(nodeNameStack) // Consume terminating node of child
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
                nextToken = reader.nextTokenOf<XmlToken.BeginElement>(nodeNameStack)
                nextToken = reader.peek()
                require(nextToken is XmlToken.BeginElement) { "Expected begin tag but got ${nextToken::class}"}
            }

            require(nextToken.name == mapInfo.entry) { "Expected node named ${mapInfo.entry} but got ${nextToken.name}" }
            reader.nextTokenOf<XmlToken.BeginElement>(nodeNameStack)
        }

        return when (val nt = reader.peek()) {
            XmlToken.EndDocument -> false
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nt.name == beginNode.name) {
                    false
                } else {
                    reader.nextTokenOf<XmlToken.EndElement>(nodeNameStack) // Consume terminating node of child
                    hasNextEntry() // recurse
                }
            else -> true
        }
    }

    private fun getListWrapperName(descriptor: SdkFieldDescriptor): String {
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
        val mapInfo = (descriptor.kind as SerialKind.Map).traits.first { it is XmlMap } as XmlMap
        reader.consumeEndToken(nodeNameStack)

        val keyToken = reader.peek()
        require(keyToken is XmlToken.BeginElement) { "Expected BeginElement, got $keyToken" }
        require(keyToken.name == mapInfo.keyName) { "Expected key name to be ${mapInfo.keyName} but got ${keyToken.name}" }
        val key = deserializer.deserializeStruct(descriptor).deserializeString()
        reader.consumeEndToken(nodeNameStack)

        val valueToken = reader.nextTokenOf<XmlToken.BeginElement>(nodeNameStack)

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
                val endToken = reader.nextTokenOf<XmlToken.EndElement>(nodeNameStack)

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

                if (!isContainerType(field)) {
                    reader.nextTokenOf<XmlToken.BeginElement>(nodeNameStack)
                }

                rt
            }
            else -> throw DeserializationException("Unexpected token $nt")
        }
    }

    private fun isContainerType(field: SdkFieldDescriptor?): Boolean {
        // Hacky policy as a way of giving a hint to the deserializer to not consume start token so it can
        // be passed to the nested deserializer.  If works, codify into a specific type SdkNestedObjectDescriptor or something.
        return when {
            field is SdkObjectDescriptor -> true
            field?.kind is SerialKind.List -> true
            field?.kind is SerialKind.Map -> true
            field?.kind is SerialKind.Struct -> true
            field == null -> true // Unknown field which will be skipped
            else -> false
        }
    }

    // Deserializer.FieldIterator
    override fun skipValue() {
        if (!reader.consumeEndToken(nodeNameStack)) reader.skipNext()
    }

    override fun deserializeByte(): Byte {
        reader.consumeEndToken(nodeNameStack)
        return deserializer.deserializeByte()
    }

    override fun deserializeInt(): Int {
        reader.consumeEndToken(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)

        return deserializer.deserializeInt()
    }

    override fun deserializeShort(): Short {
        reader.consumeEndToken(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeShort()
    }

    override fun deserializeLong(): Long {
        reader.consumeEndToken(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeLong()
    }

    override fun deserializeFloat(): Float {
        reader.consumeEndToken(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeFloat()
    }

    override fun deserializeDouble(): Double {
        reader.consumeEndToken(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeDouble()
    }

    override fun deserializeString(): String {
        reader.consumeEndToken(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeString()
    }

    override fun deserializeBool(): Boolean {
        reader.consumeEndToken(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeBool()
    }
}

private fun XmlStreamReader.consumeEndToken(nodeNameStack: MutableList<String>): Boolean {
    if (peek() is XmlToken.EndElement) {
        //skipNext()
        this.nextTokenOf<XmlToken.EndElement>(nodeNameStack)
        return true
    }
    return false
}

// return the next token and require that it be of type [TExpected] or else throw an exception
private inline fun <reified TExpected : XmlToken> XmlStreamReader.nextTokenOf(nodeNameStack: MutableList<String>): TExpected {
    val token = this.nextToken()
    requireToken<TExpected>(token)

    when(TExpected::class) {
        XmlToken.BeginElement::class -> nodeNameStack.add((token as XmlToken.BeginElement).name)
        XmlToken.EndElement::class -> {
            val lastNodeName = nodeNameStack.removeAt(nodeNameStack.size - 1)
            val currentNodeName = (token as XmlToken.EndElement).name
            require(currentNodeName == lastNodeName) { "Expected to pop $lastNodeName but found $currentNodeName in $nodeNameStack." }
        }
    }

    return token as TExpected
}

// require that the given token be of type [TExpected] or else throw an exception
private inline fun <reified TExpected> requireToken(token: XmlToken) {
    if (token::class != TExpected::class) {
        throw DeserializerStateException("expected ${TExpected::class}; found ${token::class}")
    }
}

fun XmlStreamReader.consumeListWrapper(descriptor: SdkFieldDescriptor, nodeNameStack: MutableList<String>) {
    val nt = this.peek()
    if (nt is XmlToken.BeginElement) {
        val listInfo = (descriptor.kind as SerialKind.List).traits.first { it is XmlList } as XmlList
        require(nt.name == listInfo.elementName) { "Expected ${listInfo.elementName} but found ${nt.name}" }
        this.nextTokenOf<XmlToken.BeginElement>(nodeNameStack)
    }
}