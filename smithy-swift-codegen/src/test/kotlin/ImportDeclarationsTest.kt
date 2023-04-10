/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.ImportDeclarations

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

    @Test
    fun `it renders @testable declarations`() {
        val subject = ImportDeclarations()
        subject.addImport("MyPackage", true)
        assertEquals("@testable import MyPackage", subject.toString())
    }

    @Test
    fun `it preserves @testable declarations`() {
        val subject = ImportDeclarations()
        subject.addImport("MyPackage", true)
        subject.addImport("MyPackage", false)
        assertEquals("@testable import MyPackage", subject.toString())
    }

    @Test
    fun `it renders a single @_spi() declaration`() {
        val subject = ImportDeclarations()
        subject.addImport("MyPackage", false, "MyInternalAPI")
        assertEquals("@_spi(MyInternalAPI) import MyPackage", subject.toString())
    }

    @Test
    fun `it renders a single @_spi() and @testable declaration`() {
        val subject = ImportDeclarations()
        subject.addImport("MyPackage", true, "MyInternalAPI")
        assertEquals("@testable @_spi(MyInternalAPI) import MyPackage", subject.toString())
    }

    @Test
    fun `it renders multiple @_spi() declarations`() {
        val subject = ImportDeclarations()
        subject.addImport("MyPackage", false, "MyInternalAPI1")
        subject.addImport("MyPackage", false, "MyInternalAPI2")
        assertEquals("@_spi(MyInternalAPI1) @_spi(MyInternalAPI2) import MyPackage", subject.toString())
    }

    @Test
    fun `it deduplicates @_spi() declarations`() {
        val subject = ImportDeclarations()
        subject.addImport("MyPackage", false, "MyInternalAPI1")
        subject.addImport("MyPackage", false, "MyInternalAPI2")
        subject.addImport("MyPackage", false, "MyInternalAPI1")
        subject.addImport("MyPackage", false, "MyInternalAPI2")
        assertEquals("@_spi(MyInternalAPI1) @_spi(MyInternalAPI2) import MyPackage", subject.toString())
    }
}
