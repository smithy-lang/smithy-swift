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

import com.google.gson.stream.JsonReader
import com.google.gson.stream.JsonToken as RawToken
import java.nio.charset.Charset
import software.aws.clientrt.serde.DeserializationException

private class JsonStreamReaderGson(payload: ByteArray, charset: Charset = Charsets.UTF_8) : JsonStreamReader {
    private val reader = JsonReader(payload.inputStream().reader(charset))

    override fun nextToken(): JsonToken {
        val token = when (reader.peek()) {
            RawToken.BEGIN_ARRAY -> {
                reader.beginArray()
                JsonToken.BeginArray
            }
            RawToken.END_ARRAY -> {
                reader.endArray()
                JsonToken.EndArray
            }
            RawToken.BEGIN_OBJECT -> {
                reader.beginObject()
                JsonToken.BeginObject
            }
            RawToken.END_OBJECT -> {
                reader.endObject()
                JsonToken.EndObject
            }
            RawToken.NAME -> JsonToken.Name(reader.nextName())
            RawToken.STRING -> JsonToken.String(reader.nextString())
            RawToken.NUMBER -> JsonToken.Number(reader.nextDouble())
            RawToken.BOOLEAN -> JsonToken.Bool(reader.nextBoolean())
            RawToken.NULL -> {
                reader.nextNull()
                JsonToken.Null
            }
            RawToken.END_DOCUMENT -> JsonToken.EndDocument
            else -> throw DeserializationException("unknown JSON token encountered during deserialization")
        }

        return token
    }

    override fun skipNext() = reader.skipValue()
}

/*
* Creates a [JsonStreamReader] instance
*/
internal fun JsonStreamReader(payload: ByteArray): JsonStreamReader = JsonStreamReaderGson(payload)
