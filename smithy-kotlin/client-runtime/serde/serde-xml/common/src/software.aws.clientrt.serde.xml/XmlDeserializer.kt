/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.DeserializerStateException
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor

class XmlDeserializer(private val reader: XmlStreamReader) : Deserializer, Deserializer.ElementIterator, Deserializer.FieldIterator, Deserializer.EntryIterator {
    constructor(input: ByteArray) : this(xmlStreamReader(input))

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
        val token = nextToken<XmlToken.BeginElement>()
        require(token.name == descriptor?.serialName ?: throw IllegalArgumentException("input unexpectedly passed null serialName: $descriptor")) { "expected element named ${descriptor.serialName} but got ${token.name}."}
        return this
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

        val node = nextToken<XmlToken.BeginElement>()

        require(node.name == descriptor.serialName) { "Expected node named ${descriptor.serialName} but got ${node.name} instead."}

        val rt = nextToken<XmlToken.Text>()

        val rv = rt.value ?: throw IllegalStateException("Expected value but text of element was empty.")
        val et = reader.nextToken()

        require(et is XmlToken.EndElement) { "Expected ${XmlToken.Text::class} but have ${et}." }

        return transform(rv) ?: throw IllegalArgumentException("Cannot parse $rv with ${transform::class}")
    }

    override fun nextField(descriptor: SdkObjectDescriptor): Int {
        return when (reader.nextToken()) {
            is XmlToken.EndElement -> {
                // consume the token
                Deserializer.FieldIterator.EXHAUSTED
            }
            XmlToken.EndDocument -> Deserializer.FieldIterator.EXHAUSTED
            else -> {
                val token = nextToken<XmlToken.BeginElement>()
                val propertyName = token.name
                val field = descriptor.fields.find { it.serialName == propertyName }
                field?.index ?: Deserializer.FieldIterator.UNKNOWN_FIELD
            }
        }
    }

    override fun skipValue() {
        // stream reader skips the *next* token
        TODO()
    }
}