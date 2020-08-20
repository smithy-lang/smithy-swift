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
package software.aws.clientrt.serde.json

import software.aws.clientrt.serde.*

private enum class IteratorMode {
    LIST,
    MAP,
}

class JsonDeserializer(payload: ByteArray) : Deserializer, Deserializer.ElementIterator, Deserializer.FieldIterator, Deserializer.EntryIterator {
    private val reader = jsonStreamReader(payload)

    private var iteratorMode = IteratorMode.LIST

    private fun switchIterationMode(mode: IteratorMode) {
        iteratorMode = mode
    }

    // return the next token and require that it be of type [TExpected] or else throw an exception
    private inline fun <reified TExpected : JsonToken> nextToken(): TExpected {
        val token = reader.nextToken()
        requireToken<TExpected>(token)
        return token as TExpected
    }

    // require that the given token be of type [TExpected] or else throw an exception
    private inline fun <reified TExpected> requireToken(token: JsonToken) {
        if (token::class != TExpected::class) {
            throw DeserializerStateException("expected ${TExpected::class}; found ${token::class}")
        }
    }

    // deserializing a single byte isn't common in JSON - we are going to assume that bytes are represented
    // as numbers and user understands any truncation issues. `deserializeByte` is more common in binary
    // formats (e.g. protobufs) where the binary encoding stores metadata in a single byte (e.g. flags or headers)
    override fun deserializeByte(): Byte = nextNumberValue { it.toByteOrNull() ?: it.toDouble().toByte() }

    override fun deserializeInt(): Int = nextNumberValue { it.toIntOrNull() ?: it.toDouble().toInt() }

    override fun deserializeShort(): Short = nextNumberValue { it.toShortOrNull() ?: it.toDouble().toShort() }

    override fun deserializeLong(): Long = nextNumberValue { it.toLongOrNull() ?: it.toDouble().toLong() }

    override fun deserializeFloat(): Float = deserializeDouble().toFloat()

    override fun deserializeDouble(): Double = nextNumberValue { it.toDouble() }

    // assert the next token is a Number and execute [block] with the raw value as a string. Returns result
    // of executing the block. This is mostly so that numeric conversions can keep as much precision as possible
    private fun <T> nextNumberValue(block: (value: String) -> T): T {
        val token = nextToken<JsonToken.Number>()
        return block(token.value)
    }

    override fun deserializeString(): String {
        // allow for tokens to be consumed as string even when the next token isn't a quoted string
        return when (val token = reader.nextToken()) {
            is JsonToken.String -> token.value
            is JsonToken.Number -> token.value
            is JsonToken.Bool -> token.value.toString()
            is JsonToken.Null -> "null"
            else -> throw DeserializationException("$token cannot be deserialized as type String")
        }
    }

    override fun deserializeBool(): Boolean {
        val token = nextToken<JsonToken.Bool>()
        return token.value
    }

    override fun deserializeStruct(descriptor: SdkFieldDescriptor?): Deserializer.FieldIterator {
        nextToken<JsonToken.BeginObject>()
        return this
    }

    override fun nextField(descriptor: SdkObjectDescriptor): Int {
        return when (reader.peek()) {
            RawJsonToken.EndObject -> {
                // consume the token
                nextToken<JsonToken.EndObject>()
                Deserializer.FieldIterator.EXHAUSTED
            }
            RawJsonToken.EndDocument -> Deserializer.FieldIterator.EXHAUSTED
            else -> {
                val token = nextToken<JsonToken.Name>()
                val propertyName = token.value
                val field = descriptor.fields.find { it.serialName == propertyName }
                field?.index ?: Deserializer.FieldIterator.UNKNOWN_FIELD
            }
        }
    }

    override fun skipValue() {
        // stream reader skips the *next* token
        reader.skipNext()
    }

    override fun deserializeList(): Deserializer.ElementIterator {
        nextToken<JsonToken.BeginArray>()
        switchIterationMode(IteratorMode.LIST)
        return this
    }

    override fun deserializeMap(): Deserializer.EntryIterator {
        nextToken<JsonToken.BeginObject>()
        switchIterationMode(IteratorMode.MAP)
        return this
    }

    override fun key(): String {
        val token = nextToken<JsonToken.Name>()
        return token.value
    }

    // next has to work for different modes of iteration (list vs map entries)
    override fun next(): Int {
        return when (iteratorMode) {
            IteratorMode.LIST -> nextList()
            IteratorMode.MAP -> nextMap()
        }
    }

    private fun nextMap(): Int {
        return when (reader.peek()) {
            RawJsonToken.EndObject -> {
                // consume the token
                nextToken<JsonToken.EndObject>()
                Deserializer.EntryIterator.EXHAUSTED
            }
            RawJsonToken.EndDocument -> Deserializer.EntryIterator.EXHAUSTED
            else -> 0
        }
    }

    private fun nextList(): Int {
        return when (reader.peek()) {
            RawJsonToken.EndArray -> {
                // consume the token
                nextToken<JsonToken.EndArray>()
                Deserializer.ElementIterator.EXHAUSTED
            }
            RawJsonToken.EndDocument -> Deserializer.ElementIterator.EXHAUSTED
            else -> 0
        }
    }
}
