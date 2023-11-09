/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

class ImportDeclarations {
    private val imports = mutableSetOf<ImportStatement>()

    fun addImport(
        packageName: String,
        isTestable: Boolean = false,
        internalSPIName: String? = null,
        importOnlyIfCanImport: Boolean = false
    ) {
        val existingImport = imports.find { it.packageName == packageName }
        if (existingImport != null) {
            // Update isTestable to true if needed
            existingImport.isTestable = existingImport.isTestable || isTestable
            // If we have an existing import with the same package name, then add the SPI name to the existing list
            if (internalSPIName != null) {
                existingImport.internalSPINames.add(internalSPIName)
            }
            // Update importOnlyIfCanImport to true if needed
            existingImport.importOnlyIfCanImport = existingImport.importOnlyIfCanImport || importOnlyIfCanImport
        } else {
            // Otherwise, we have a new package to import, so add it
            val internalSPINames = listOf(internalSPIName).mapNotNull { it }.toMutableSet()
            imports.add(ImportStatement(packageName, isTestable, internalSPINames, importOnlyIfCanImport))
        }
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

private data class ImportStatement(
    val packageName: String,
    var isTestable: Boolean,
    val internalSPINames: MutableSet<String>,
    var importOnlyIfCanImport: Boolean
) {
    val statement: String
        get() {
            var import = "import $packageName"
            for (internalSPIName in internalSPINames.sorted().reversed()) {
                import = "@_spi($internalSPIName) $import"
            }
            if (isTestable) {
                import = "@testable $import"
            }
            if (importOnlyIfCanImport) {
                import =
                    """
                    #if canImport($packageName)
                    $import
                    #endif
                    """.trimIndent()
            }
            return import
        }

    override fun toString(): String = statement
}
