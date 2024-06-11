/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyFormURLTypes {
    val Writer = runtimeSymbol("Writer", SwiftDeclaration.CLASS)
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.SMITHY_FORM_URL,
    null,
)
