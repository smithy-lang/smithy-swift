/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.swift.codegen.SwiftWriter
import java.util.UUID

/**
 * A class which uses a writer to "record" code into an in-memory buffer,
 * then "plays it back" onto the writer at a later time.
 *
 * Useful when the result of rendering an expression is needed before the expression
 * is actually rendered into code.
 */
class BufferWriter(
    val writer: SwiftWriter,
    private val mutableBuffer: MutableList<String> = mutableListOf()
) {
    /**
     * Record whatever text is written in the block to the internal buffer.
     */
    fun record(block: (SwiftWriter) -> Unit) {
        // Create a random string to use as a section identifier.
        val sectionID = UUID.randomUUID().toString()

        // Open a new section on the writer.
        writer.pushState(sectionID)

        // onSection will "intercept" the code written to the given section and
        // allow it to be redirected using the trailing closure.
        writer.onSection(sectionID) {
            val text = it as? String
            if (text != null) {
                // Text sometimes comes in as multiple strings, so trim indentation then split it
                mutableBuffer.addAll(text.trimIndent().split("\n"))
            }
        }

        // Perform the writes performed in the trailing closure to this function.
        block(writer)

        // Close the section, returning the writer to its previous state.
        writer.popState()
    }

    /**
     * Write the contents of the buffer to the writer, then erase the buffer.
     */
    fun playback() {
        mutableBuffer.forEach { writer.write(it) }
        mutableBuffer.removeAll { true }
    }
}
