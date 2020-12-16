/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class ImportDeclarationsTest {
    @Test
    fun `it renders imports`() {

        val decls = ImportDeclarations()

        decls.addImport("Foundation")
        decls.addImport("ComplexModule")

        val statements = decls.toString()
        val expected = "import ComplexModule\nimport Foundation"
        assertEquals(expected, statements)
    }

    @Test
    fun `it filters duplicates`() {
        val decls = ImportDeclarations()

        decls.addImport("Foundation")
        decls.addImport("Foundation")

        val statements = decls.toString()
        val expected = "import Foundation"
        assertEquals(expected, statements)
    }
}
