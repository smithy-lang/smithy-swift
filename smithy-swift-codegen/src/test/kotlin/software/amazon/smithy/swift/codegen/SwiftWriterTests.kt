/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test

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
