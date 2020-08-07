/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import software.aws.clientrt.serde.*

class XmlDeserializer(private val reader: XmlStreamReader) : Deserializer, Deserializer.ElementIterator, Deserializer.FieldIterator, Deserializer.EntryIterator {
    constructor(input: ByteArray) : this(xmlStreamReader(input))

    // Stores the name of the last start node, used to detect trailing end tokens.
    private var lastNode: XmlToken.BeginElement? = null

    private val containerNodeStack = mutableListOf<XmlToken.BeginElement>()

    // return the next token and require that it be of type [TExpected] or else throw an exception
    private inline fun <reified TExpected : XmlToken> nextToken(): TExpected {
        val token = reader.nextToken()
        requireToken<TExpected>(token)
        return token as TExpected
    }

    // require that the given token be of type [TExpected] or else throw an exception
    private inline fun <reified TExpected> requireToken(token: XmlToken) {
        if (token::class != TExpected::class) {
            throw DeserializerStateException("expected ${TExpected::class}; found ${token::class}")
        }
    }

    override fun deserializeStruct(descriptor: SdkFieldDescriptor?): Deserializer.FieldIterator {
        containerNodeStack.add(testAndRemoveContainer(descriptor))
        return this
    }

    override fun deserializeList(descriptor: SdkFieldDescriptor?): Deserializer.ElementIterator {
        containerNodeStack.add(testAndRemoveContainer(descriptor))
        return this
    }

    override fun deserializeMap(descriptor: SdkFieldDescriptor?): Deserializer.EntryIterator {
        containerNodeStack.add(testAndRemoveContainer(descriptor))
        return this
    }

    private fun testAndRemoveContainer(descriptor: SdkFieldDescriptor?): XmlToken.BeginElement {
        require(descriptor is XmlFieldDescriptor) { "Expected XmlFieldDescriptor but got $descriptor"}

        trimEndToken()

        val token = nextToken<XmlToken.BeginElement>()
        lastNode = token
        require(token.name == descriptor.nodeName) {
            "expected element named ${descriptor.nodeName} but got ${token.name}."
        }

        return token
    }

    private fun trimEndToken(): XmlToken.EndElement? {
        val peekedNode = reader.peek()
        if (peekedNode is XmlToken.EndElement && peekedNode.name == lastNode?.name) {
            reader.nextToken() // Trim trailing end frahom previous node
            return peekedNode
        }
        return null
    }

    @ExperimentalStdlibApi
    override fun next(): Int {
        val trimmedToken = trimEndToken()

        if (trimmedToken?.name == containerNodeStack.lastOrNull()?.name ) {
            containerNodeStack.removeLast()
            return Deserializer.ElementIterator.EXHAUSTED
        }

        val nt = reader.peek()

        return if (nt !is XmlToken.BeginElement) Deserializer.ElementIterator.EXHAUSTED else 0
    }

    override fun key(descriptor: SdkFieldDescriptor?) = deserializeString(descriptor)

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

        val node = nextToken<XmlToken.BeginElement>()

        require(node.name == descriptor.nodeName) { "Expected node named ${descriptor.nodeName} but got ${node.name} instead."}

        val rt = nextToken<XmlToken.Text>()

        val rv = rt.value ?: throw IllegalStateException("Expected value but text of element was empty.")
        val et = reader.nextToken()

        require(et is XmlToken.EndElement) { "Expected ${XmlToken.Text::class} but have ${et}." }

        return transform(rv) ?: throw IllegalArgumentException("Cannot parse $rv with ${transform::class}")
    }

    override fun nextField(descriptor: SdkObjectDescriptor): Int {
        trimEndToken()

        return when (val nt = reader.peek()) {
            is XmlToken.EndElement -> {
                // consume the token
                nextToken<XmlToken.EndElement>()
                Deserializer.FieldIterator.EXHAUSTED
            }
            XmlToken.EndDocument -> Deserializer.FieldIterator.EXHAUSTED
            is XmlToken.BeginElement -> {
                val propertyName = nt.name
                val field = descriptor.fields.filterIsInstance<XmlFieldDescriptor>().find { it.nodeName == propertyName }
                field?.index ?: Deserializer.FieldIterator.UNKNOWN_FIELD
            }
            else -> throw IllegalArgumentException("Unexpected token $nt")
        }
    }

    override fun skipValue() {
        reader.skipNext()
    }
}