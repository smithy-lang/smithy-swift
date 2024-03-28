/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.ImportContainer
import software.amazon.smithy.codegen.core.Symbol

class SwiftImportContainer : ImportContainer {
    private val importStatements = mutableSetOf<ImportStatement>()

    fun addImport(
        packageName: String,
        isTestable: Boolean = false,
        internalSPIName: String? = null,
        importOnlyIfCanImport: Boolean = false
    ) {
        importStatements.find { it.packageName == packageName }?.let {
            // Update isTestable to true if needed
            it.isTestable = it.isTestable || isTestable
            // If we have an existing import with the same package name, then add the SPI name to the existing list
            if (internalSPIName != null) {
                it.internalSPINames.add(internalSPIName)
            }
            // Update importOnlyIfCanImport to true if needed
            it.importOnlyIfCanImport = it.importOnlyIfCanImport || importOnlyIfCanImport
        } ?: run {
            val internalSPINames = listOf(internalSPIName).mapNotNull { it }.toMutableSet()
            importStatements.add(ImportStatement(packageName, isTestable, internalSPINames, importOnlyIfCanImport))
        }
    }

    override fun importSymbol(symbol: Symbol, alias: String) {
        symbol.dependencies
            .forEach { addImport(it.packageName, false) }
    }

    override fun toString(): String {
        if (importStatements.isEmpty()) {
            return ""
        }

        return importStatements
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
