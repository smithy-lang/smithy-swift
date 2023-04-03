/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

class ImportDeclarations {
    private val imports = mutableSetOf<ImportStatement>()

    fun addImport(packageName: String, isTestable: Boolean = false, internalSPIName: String? = null) {
        if (internalSPIName != null && internalSPIName != "Internal") {
            throw IllegalArgumentException(
                """
                We currently only support usage of a single spiName 'Internal'. 
                If you'd like to use another name then please update the logic below to fully support multiple spiNames.
                """
            )
        }

        val existingImport = imports.find { it.packageName == packageName }
        if (existingImport != null) {
            // If we have an existing import with the same package name, then replace the existing one
            val newImport = ImportStatement(
                packageName,
                isTestable || existingImport.isTestable,
                internalSPIName ?: existingImport.internalSPIName
            )
            imports.remove(existingImport)
            imports.add(newImport)
            return
        }

        // Otherwise, we have a new import so add it
        imports.add(ImportStatement(packageName, isTestable, internalSPIName))
    }

    override fun toString(): String {
        if (imports.isEmpty()) {
            return ""
        }

        return imports
            .sortedBy { it.packageName }
            .map(ImportStatement::statement)
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
