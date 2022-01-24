/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

class ImportDeclarations {
    private val imports = mutableSetOf<ImportStatement>()

    fun addImport(target: String, isTestable: Boolean = false) {
        imports.add(ImportStatement(target, isTestable))
    }

    override fun toString(): String {
        if (imports.isEmpty()) {
            return ""
        }

        return imports
            .map(ImportStatement::statement)
            .sorted()
            .joinToString(separator = "\n")
    }
}

private data class ImportStatement(val target: String, val isTestable: Boolean) {
    val statement: String
        get() {
            if (isTestable) {
                return "@testable import $target"
            }
            return "import $target"
        }

    override fun toString(): String = statement
}
