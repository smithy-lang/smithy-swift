/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen
import software.amazon.smithy.swift.codegen.lang.reservedWords
import software.amazon.smithy.utils.CaseUtils

fun String.removeSurroundingBackticks() = removeSurrounding("`", "`")

/**
 * Creates an idiomatic name for swift enum cases given an optional name and value.
 * Uses either name or value attributes of EnumDefinition in that order and formats
 * them to camelCase after removing chars except alphanumeric, space and underscore.
 */
fun swiftEnumCaseName(name: String?, value: String, shouldBeEscaped: Boolean = true): String {
    val resolvedName = name ?: value
    var enumCaseName = CaseUtils.toCamelCase(resolvedName.replace(Regex("[^a-zA-Z0-9_ ]"), ""))
    if (!SymbolVisitor.isValidSwiftIdentifier(enumCaseName)) {
        enumCaseName = "_$enumCaseName"
    }

    if (shouldBeEscaped && reservedWords.contains(enumCaseName)) {
        enumCaseName = SymbolVisitor.escapeReservedWords(enumCaseName)
    }

    return enumCaseName
}
