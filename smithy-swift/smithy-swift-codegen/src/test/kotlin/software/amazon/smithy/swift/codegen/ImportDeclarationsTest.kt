package software.amazon.smithy.swift.codegen

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

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class ImportDeclarationsTest {
    @Test
    fun `it renders imports`() {

        val decls = ImportDeclarations()

        decls.addImport("Foundation")
        decls.addImport("BigNumber")

        val statements = decls.toString()
        val expected = "import BigNumber\nimport Foundation"
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