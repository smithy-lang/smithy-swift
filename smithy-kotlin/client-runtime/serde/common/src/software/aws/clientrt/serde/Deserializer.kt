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

interface Deserializer : PrimitiveDeserializer {
    fun deserializeStruct(descriptor: SdkFieldDescriptor?): FieldIterator

//    fun deserializeMap(descriptor: SdkFieldDescriptor)

    fun deserializeList(): ElementIterator

    /**
     * Iterator over raw elements in a collection
     */
    interface ElementIterator : PrimitiveDeserializer {
        /**
         * Advance to the next element. Returns [EXHAUSTED] when no more elements are in the list
         * or the document has been read completely.
         */
        fun next(): Int

        companion object {
            /**
             * The iterator has been exhausted, no more fields will be returned by [next]
             */
            val EXHAUSTED = -1
        }
    }

    /**
     * Iterator over struct fields
     */
    interface FieldIterator : PrimitiveDeserializer {
        /**
         * Returns the index of the next field found or one of the defined constants
         */
        fun nextField(descriptor: SdkObjectDescriptor): Int

        /**
         * Skip the next field value recursively. Meant for discarding unknown fields
         */
        fun skipValue()

        companion object {
            /**
             * An unknown field was encountered
             */
            const val UNKNOWN_FIELD = -1

            /**
             * The iterator has been exhausted, no more fields will be returned by [nextField]
             */
            const val EXHAUSTED = -2
        }
    }
}

fun Deserializer.deserializeStruct(descriptor: SdkFieldDescriptor?, block: Deserializer.FieldIterator.() -> Unit) {
    val iter = deserializeStruct(descriptor)
    iter.apply(block)
}

fun <T> Deserializer.deserializeList(block: Deserializer.ElementIterator.() -> T): T {
    val deserializer = deserializeList()
    val result = block(deserializer)
    return result
}

/**
 * Common interface for deserializing primitive values
 */
interface PrimitiveDeserializer {
    /**
     * Deserialize and return the next token as a [Byte]
     */
    fun deserializeByte(): Byte

    /**
     * Deserialize and return the next token as an [Int]
     */
    fun deserializeInt(): Int

    /**
     * Deserialize and return the next token as a [Short]
     */
    fun deserializeShort(): Short

    /**
     * Deserialize and return the next token as a [Long]
     */
    fun deserializeLong(): Long

    /**
     * Deserialize and return the next token as a [Float]
     */
    fun deserializeFloat(): Float

    /**
     * Deserialize and return the next token as a [Double]
     */
    fun deserializeDouble(): Double

    /**
     * Deserialize and return the next token as a [String]
     */
    fun deserializeString(): String

    /**
     * Deserialize and return the next token as a [Boolean]
     */
    fun deserializeBool(): Boolean

    // TODO
    // deserializeBigInt(): BigInteger
    // deserializeBigDecimal(): BigDecimal
}
