/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

class ImportDeclarations {
    private val imports = mutableSetOf<ImportStatement>()

    fun addImport(packageName: String, isTestable: Boolean = false, internalSPIName: String? = null) {
        imports.add(ImportStatement(packageName, isTestable, internalSPIName))
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

private data class ImportStatement(val packageName: String, val isTestable: Boolean, val internalSPIName: String?) {
    val statement: String
        get() {
            var import = "import $packageName"
            if (internalSPIName != null) {
                import = "@_spi($internalSPIName) $import"
            }
            if (isTestable) {
                import = "@testable $import"
            }
            return import
        }

    override fun toString(): String = statement
}
