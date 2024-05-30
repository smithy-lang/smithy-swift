/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.model.buildSymbol

object FoundationTypes {
    val TimeInterval = builtInSymbol("TimeInterval", SwiftDeclaration.TYPEALIAS)
}

private fun builtInSymbol(symbol: String, declaration: SwiftDeclaration? = null) = buildSymbol {
    name = symbol
    declaration?.let { this.setProperty("decl", it.keyword) }
    namespace = "Foundation"
}
