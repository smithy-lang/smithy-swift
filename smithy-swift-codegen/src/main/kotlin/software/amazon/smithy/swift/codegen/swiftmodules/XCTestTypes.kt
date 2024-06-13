/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object XCTestTypes {
    val XCTestCase = runtimeSymbol("XCTestCase")
}

private fun runtimeSymbol(name: String, declaration: SwiftDeclaration? = null, spiName: String? = null): Symbol = SwiftSymbol.make(
    name,
    declaration,
    SwiftDependency.NONE,
    spiName,
)
