/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyTimestampsTypes {
    val TimestampFormatter = runtimeSymbol("TimestampFormatter", SwiftDeclaration.STRUCT)
    val TimestampFormat = runtimeSymbol("TimestampFormat", SwiftDeclaration.ENUM)
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration
): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_TIMESTAMPS,
    emptyList(),
    listOf("SmithyTimestamps"),
)
