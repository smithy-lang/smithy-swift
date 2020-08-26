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
 *
 * TODO: To verify correctness, a stack of open node names is maintained to match expected against actual node traversal.
 * TODO: This is not necessary for parsing and should be removed before GA.
 */
class XmlDeserializer(private val reader: XmlStreamReader, private val nodeNameStack: MutableList<XmlToken.QualifiedName> = mutableListOf()) : Deserializer {
    constructor(input: ByteArray) : this(xmlStreamReader(input))

    /**
     * Deserialize an element with children of arbitrary values.
     *
     * @param descriptor A SdkFieldDescriptor which defines the name of the node wrapping the struct values.
     */
    override fun deserializeStruct(descriptor: SdkObjectDescriptor): Deserializer.FieldIterator {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)

        val beginNode = reader.takeToken<XmlToken.BeginElement>(nodeNameStack) //Consume the container start tag

        return XmlFieldIterator(this, reader.currentDepth(), reader, beginNode, descriptor, nodeNameStack)
    }

    /**
     * Deserialize an element with identically-typed children.
     */
    override fun deserializeList(descriptor: SdkFieldDescriptor): Deserializer.ElementIterator {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack) 

        val beginNode = reader.takeToken<XmlToken.BeginElement>(nodeNameStack) //Consume the container start tag
        require(descriptor.serialName == beginNode.name.name) { "Expected list start tag of ${beginNode.name} but got ${descriptor.serialName}" }

        return CompositeIterator(this, reader.currentDepth(), reader, beginNode, descriptor, nodeNameStack)
    }

    /**
     * Deserialize an element with identically-typed children of key/value pairs.
     */
    override fun deserializeMap(descriptor: SdkFieldDescriptor): Deserializer.EntryIterator {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)

        val beginNode = reader.takeToken<XmlToken.BeginElement>(nodeNameStack) //Consume the container start tag
        require(descriptor.serialName == beginNode.name.name) { "Expected map start tag of ${beginNode.name} but got ${descriptor.serialName}" }

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
        val rt = reader.takeToken<XmlToken.Text>(nodeNameStack)

        val rv = rt.value ?: throw DeserializationException("Expected value but text of element was null.")
        return transform(rv) ?: throw DeserializationException("Cannot parse $rv with ${transform::class}")
    }
}

/**
 * Captures state and implements interfaces necessary to deserialize Lists and Maps.
 */
private class CompositeIterator(
    private val deserializer: Deserializer,
    private val depth: Int,
    private val reader: XmlStreamReader,
    private val beginNode: XmlToken.BeginElement,
    private val descriptor: SdkFieldDescriptor,
    private val nodeNameStack: MutableList<XmlToken.QualifiedName>
) : Deserializer.EntryIterator, Deserializer.ElementIterator {

    private var consumedWrapper = false // Signals if outermost tag initially passed to CompositeIterator has been taken

    // Deserializer.EntryIterator, Deserializer.ElementIterator
    override fun hasNextElement(): Boolean {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        if (!consumedWrapper) {
            val nextToken = reader.peekToken<XmlToken.BeginElement>()
            require(nextToken.name.name == descriptor.getWrapperName()) { "Expected entry wrapper ${descriptor.serialName} but got ${nextToken.name}" }
            consumedWrapper = true
        }

        return when (val nextToken = reader.peek()) {
            XmlToken.EndDocument -> false
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nextToken.name == beginNode.name) {
                    false
                } else {
                    reader.takeToken<XmlToken.EndElement>(nodeNameStack) // Consume terminating node of child
                    hasNextElement() // recurse
                }
            else -> true
        }
    }

    override fun hasNextEntry(): Boolean {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        reader.takeIfToken<XmlToken.BeginElement>(nodeNameStack) { beginToken ->
            val mapInfo = descriptor.expectTrait<XmlMap>()
            if (!consumedWrapper && !mapInfo.flattened) {
                val expectedWrapperName = descriptor.getWrapperName()
                require(beginToken.name.name == expectedWrapperName) { "Expected entry wrapper ${descriptor.serialName} but got $expectedWrapperName" }
                consumedWrapper = true
                val nextToken = reader.takeToken<XmlToken.BeginElement>(nodeNameStack)
                require(nextToken.name.name == mapInfo.entry) { "Expected node ${mapInfo.entry} but got ${nextToken.name}" }
                reader.peekToken<XmlToken.BeginElement>()
            }
        }

        return when (val nextToken = reader.peek()) {
            XmlToken.EndDocument -> false
            is XmlToken.EndElement ->
                if (reader.currentDepth() == depth && nextToken.name == beginNode.name) {
                    false
                } else {
                    reader.takeToken<XmlToken.EndElement>(nodeNameStack) // Consume terminating node of child
                    hasNextEntry() // recurse
                }
            else -> true
        }
    }

    // Deserializer.EntryIterator
    override fun key(): String {
        val mapInfo = descriptor.expectTrait<XmlMap>()
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)

        val keyStartToken = reader.takeToken<XmlToken.BeginElement>(nodeNameStack)
        require(keyStartToken.name.name == mapInfo.keyName) { "Expected key name to be ${mapInfo.keyName} but got ${keyStartToken.name}" }
        val key = reader.takeToken<XmlToken.Text>(nodeNameStack).value ?: error("Expected string value for key, but found null.")
        val keyEndToken = reader.takeToken<XmlToken.EndElement>(nodeNameStack)
        require(keyEndToken.name.name == mapInfo.keyName) { "Expected key name to be ${mapInfo.keyName} but got ${keyStartToken.name}" }

        val valueToken = reader.takeToken<XmlToken.BeginElement>(nodeNameStack)

        require(valueToken.name.name == mapInfo.valueName)

        return key
    }

    override fun deserializeByte(): Byte {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)

        return deserializer.deserializeByte()
    }

    override fun deserializeInt(): Int {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)

        return deserializer.deserializeInt()
    }

    override fun deserializeShort(): Short {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeShort()
    }

    override fun deserializeLong(): Long {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeLong()
    }

    override fun deserializeFloat(): Float {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeFloat()
    }

    override fun deserializeDouble(): Double {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeDouble()
    }

    override fun deserializeString(): String {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeString()
    }

    override fun deserializeBool(): Boolean {
        reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)
        reader.consumeListWrapper(descriptor, nodeNameStack)
        return deserializer.deserializeBool()
    }
}

private class XmlFieldIterator(
    private val deserializer: Deserializer,
    private val depth: Int,
    private val reader: XmlStreamReader,
    private val beginNode: XmlToken.BeginElement,
    private val descriptor: SdkObjectDescriptor,
    private val nodeNameStack: MutableList<XmlToken.QualifiedName>
) : Deserializer.FieldIterator, Deserializer by deserializer {
    // Deserializer.FieldIterator
    override fun findNextFieldIndex(): Int? {
        require(reader.currentDepth() >= depth) { "Unexpectedly traversed beyond $beginNode with depth ${reader.currentDepth()}" }

        return when (val nextToken = reader.peek()) {
            XmlToken.EndDocument -> null
            is XmlToken.EndElement -> {
                // consume the token
                val endToken = reader.takeToken<XmlToken.EndElement>(nodeNameStack)

                if (reader.currentDepth() == depth && endToken.name == beginNode.name) {
                    null
                } else {
                    findNextFieldIndex() // recurse
                }
            }
            is XmlToken.BeginElement -> {
                val propertyName = nextToken.name
                //FIXME: The following filter needs to take XML namespace into account when matching.
                val field =
                    descriptor.fields().find { it.serialName == propertyName.name }
                val rt = field?.index ?: Deserializer.FieldIterator.UNKNOWN_FIELD

                if (!isContainerType(field)) {
                    reader.takeToken<XmlToken.BeginElement>(nodeNameStack)
                }

                rt
            }
            else -> throw DeserializationException("Unexpected token $nextToken")
        }
    }

    // Deserializer.FieldIterator
    override fun skipValue() {
        if (!reader.takeIfToken<XmlToken.EndElement>(nodeNameStack)) {
            // Next token was not end, so consume the entire next node.
            reader.skipNext()
        }
    }
}

// return the next token and require that it be of type [TExpected] or else throw an exception
private inline fun <reified TExpected : XmlToken> XmlStreamReader.takeToken(nodeNameStack: MutableList<XmlToken.QualifiedName>): TExpected {
    val token = this.nextToken()
    requireToken<TExpected>(token)

    when(TExpected::class) {
        XmlToken.BeginElement::class -> nodeNameStack.add((token as XmlToken.BeginElement).name)
        XmlToken.EndElement::class -> {
            val lastNode = nodeNameStack.removeAt(nodeNameStack.size - 1)
            val currentNodeId = (token as XmlToken.EndElement).name
            require(currentNodeId == lastNode) { "Expected to pop $lastNode but found $currentNodeId in $nodeNameStack." }
        }
    }

    return token as TExpected
}

/**
 * Verify that the next token is of a specified type but do not consume it.
 */
private inline fun <reified TExpected : XmlToken> XmlStreamReader.peekToken(): TExpected {
    val token = this.peek()
    requireToken<TExpected>(token)

    return token as TExpected
}

// require that the given token be of type [TExpected] or else throw an exception
private inline fun <reified TExpected> requireToken(token: XmlToken) {
    if (token::class != TExpected::class) {
        throw DeserializerStateException("expected ${TExpected::class}; found ${token::class}")
    }
}

/**
 * If the token is of specified type, consume it and perform work against it in `block`.
 *
 * @param nodeNameStack tracks traversal through tree to verify correctness.
 * @param block function to apply expected token against.
 */
private inline fun <reified TExpected> XmlStreamReader.takeIfToken(nodeNameStack: MutableList<XmlToken.QualifiedName>, block: (TExpected) -> Unit = {}): Boolean {
    val nextToken = this.peek()

    if (nextToken::class == TExpected::class) {
        val expectedToken = this.nextToken() as TExpected

        when(TExpected::class) {
            XmlToken.BeginElement::class -> nodeNameStack.add((expectedToken as XmlToken.BeginElement).name)
            XmlToken.EndElement::class -> {
                val lastNodeName = nodeNameStack.removeAt(nodeNameStack.size - 1)
                val currentNodeName = (expectedToken as XmlToken.EndElement).name
                require(currentNodeName == lastNodeName) { "Expected to pop $lastNodeName but found $currentNodeName in $nodeNameStack." }
            }
        }

        block(expectedToken)

        return true
    }

    return false
}

private fun isContainerType(field: SdkFieldDescriptor?): Boolean {
    return when {
        field is SdkObjectDescriptor -> true
        field?.kind is SerialKind.List -> true
        field?.kind is SerialKind.Map -> true
        field?.kind is SerialKind.Object -> true
        field == null -> true // Unknown field which will be skipped
        else -> false
    }
}

/**
 * Return the top-level name of the container of a List or Map.
 */
private fun SdkFieldDescriptor.getWrapperName(): String {
    return when(this.kind) {
        is SerialKind.List -> {
            val listTrait = this.expectTrait<XmlList>()
            listTrait.elementName
        }
        is SerialKind.Map -> {
            val mapTrait = this.expectTrait<XmlMap>()
            require(!mapTrait.flattened) { "Cannot get wrapper name of flattened map." }
            mapTrait.parent ?: error("Expected XmlMap to contain non-null parent name.")
        }
        else -> error("Unexpected descriptor kind: ${this::class}")
    }
}

/**
 * If the next parse token is BeginElement on List, verify that element matches list wrapper name.
 */
fun XmlStreamReader.consumeListWrapper(descriptor: SdkFieldDescriptor, nodeNameStack: MutableList<XmlToken.QualifiedName>) =
    this.takeIfToken<XmlToken.BeginElement>(nodeNameStack) { token ->
        val listInfo = descriptor.expectTrait<XmlList>()
        //NOTE: here we'll need to match on namespace too if we are to de/serialize with namespaces.
        require(token.name.name == listInfo.elementName) { "Expected ${listInfo.elementName} but found ${token.name}" }
    }
