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
package software.aws.clientrt.serde

/**
 * Interface for serialization. Specific formats should implement this interface according to their
 * own requirements. Currently only software.aws.clientrt.serde.json.JsonSerializer implements this interface.
 */
interface Serializer {
    fun beginArray()
    fun endArray()
    fun writeNull()
    fun beginObject()
    fun endObject()
    fun writeName(fieldName: String)
    fun writeValue(value: String)
    fun writeValue(bool: Boolean)
    fun writeValue(value: Long)
    fun writeValue(value: Double)
    fun writeValue(value: Float)
    fun writeValue(value: Short)
    fun writeValue(value: Int)
    fun writeValue(value: Byte)
    fun writeNumber(number: String)
    val bytes: ByteArray?
}
