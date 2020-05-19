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
package software.aws.clientrt.io

/**
 * Supplies a stream of bytes. Use this interface to read data from wherever it’s located: from the network, storage, or a buffer in memory.
 *
 * This interface is functionally equivalent to an asynchronous coroutine compatible [java.io.InputStream]
 */
interface Source {
    /**
     * Returns number of bytes that can be read without suspension. Read operations do no suspend and return immediately when this number is at least the number of bytes requested for read.
     */
    val availableForRead: Int

    /**
     * Returns true if the channel is closed and no remaining bytes are available for read. It implies that availableForRead is zero.
     */
    val isClosedForRead: Boolean

    val isClosedForWrite: Boolean

    /**
     * Removes at least 1, and up to [requested] bytes from this and appends them to sink. Returns the number of bytes read, or -1 if this source is exhausted.
     */
    suspend fun read(sink: ByteArray, requested: Int): Int

    /**
     * Reads all length bytes to [sink] buffer or fails if source has been closed. Suspends if not enough bytes available.
     */
    suspend fun readFully(sink: ByteArray, offset: Int, length: Int)

    /**
     * Reads all available bytes to [sink] buffer and returns immediately or suspends if no bytes available
     */
    suspend fun readAvailable(sink: ByteArray, offset: Int, length: Int): Int

    /**
     * Close channel with optional cause cancellation
     */
    fun cancel(cause: Throwable?): Boolean

    companion object {
        /**
         * Creates an empty byte stream Source
         */
        // FIXME - need actual implementation
//        val Empty: Source by lazy { BufferChannel() }
    }
}
