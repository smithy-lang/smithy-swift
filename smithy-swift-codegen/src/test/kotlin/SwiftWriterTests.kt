/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.customizeSection

class SwiftWriterTests {

    @Test fun `writes doc strings`() {
        val writer = SwiftWriter("MockPackage")
        val docs = "This is a big doc string.\nMore."
        writer.writeDocs(docs)
        val result = writer.toString()
        val expectedResult =
            """
            /// This is a big doc string.
            /// More.
            """.trimIndent()
        result.shouldContain(expectedResult)
    }

    @Test fun `escapes $ in doc strings`() {
        val writer = SwiftWriter("MockPackage")
        val docs = "This is $ valid documentation."
        writer.writeDocs(docs)
        val result = writer.toString()
        result.shouldContain(createSingleLineDocComment(docs))
    }

    object TestSectionId : SectionId {
        const val a = "a"
    }
    object NestedTestSectionId : SectionId {
        const val a = "a" // intentionally collides with [TestSectionId]
    }

    @Test
    fun `it handles overriding stateful sections`() {
        val unit = SwiftWriter("MockPackage")

        unit.customizeSection(TestSectionId) { writer, previousValue ->
            val state = writer.getContext(TestSectionId.a)
            writer.write(previousValue)
            writer.write("// section with state $state")
        }

        unit.write("// before section")
        unit.declareSection(TestSectionId, mapOf(TestSectionId.a to 1)) {
            unit.write("// original in section")
        }
        unit.write("// after section")

        val expected = """
            // before section
            // original in section
            // section with state 1
            // after section
        """.trimIndent()
        val actual = unit.toString()

        actual.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it handles nested stateful sections`() {
        val unit = SwiftWriter("MockPackage")

        unit.customizeSection(TestSectionId) { writer, previousValue ->
            val state = writer.getContext(TestSectionId.a)
            writer.write("// section with state $state")
            writer.write(previousValue)
        }

        unit.customizeSection(NestedTestSectionId) { writer, _ ->
            val state = writer.getContext(NestedTestSectionId.a)
            writer.write("// nested section with state $state")
        }

        unit.write("// before section")
        unit.declareSection(TestSectionId, mapOf(TestSectionId.a to 1)) {
            unit.declareSection(NestedTestSectionId, mapOf(NestedTestSectionId.a to 2)) {
                unit.write("// original in nested section")
            }
        }
        unit.write("// after section")

        val expected = """
            // before section
            // section with state 1
            // nested section with state 2
            // after section
        """.trimIndent()
        val actual = unit.toString()

        actual.shouldContainOnlyOnce(expected)
    }

    private fun createSingleLineDocComment(docs: String): String {
        return "/// " + docs
    }
}
