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

/**
 * Raw tokens produced when reading a JSON document as a stream
 */
sealed class JsonToken {
    /**
     * The opening of a JSON array '['
     */
    object BeginArray : JsonToken()

    /**
     * The closing of a JSON array ']'
     */
    object EndArray : JsonToken()

    /**
     * The opening of a JSON object '{'
     */
    object BeginObject : JsonToken()

    /**
     * The closing of a JSON object '}'
     */
    object EndObject : JsonToken()

    /**
     * A JSON property name
     */
    data class Name(val value: kotlin.String) : JsonToken()

    /**
     * A JSON string
     */
    data class String(val value: kotlin.String) : JsonToken()

    /**
     * A JSON number
     */
    data class Number(val value: Double) : JsonToken()

    /**
     * A JSON boolean
     */
    data class Bool(val value: Boolean) : JsonToken()

    /**
     * A JSON 'null'
     */
    object Null : JsonToken()

    /**
     * The end of the JSON stream to signal that the JSON-encoded value has no more
     * tokens
     */
    object EndDocument : JsonToken()
}
