/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.SwiftWriter

class SwiftWriterTests {

    @Test fun `writes doc strings`() {
        val writer = SwiftWriter("MockPackage")
        val docs = "This is a big doc string.\nMore."
        writer.writeDocs(docs)
        val result = writer.toString()
        result.shouldContain(createMultiLineDocComment(docs))
    }

    @Test fun `escapes $ in doc strings`() {
        val writer = SwiftWriter("MockPackage")
        val docs = "This is $ valid documentation."
        writer.writeDocs(docs)
        val result = writer.toString()
        result.shouldContain(createSingleLineDocComment(docs))
    }

    private fun createMultiLineDocComment(docs: String): String {
        val docComment = docs.replace("\n", "\n ")
        return "/**\n " + docComment + "\n */\n"
    }

    private fun createSingleLineDocComment(docs: String): String {
        return "/// " + docs
    }
}
