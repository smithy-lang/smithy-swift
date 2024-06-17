/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.model.buildSymbol

object FoundationTypes {
    val Data = builtInSymbol("Data", SwiftDeclaration.STRUCT)
    val Date = builtInSymbol("Date", SwiftDeclaration.STRUCT)
    val TimeInterval = builtInSymbol("TimeInterval", SwiftDeclaration.TYPEALIAS)
    val URL = builtInSymbol("URL", SwiftDeclaration.STRUCT)
    val URLRequest = builtInNetworkingSymbol("URLRequest", SwiftDeclaration.STRUCT)
}

private fun builtInSymbol(symbol: String, declaration: SwiftDeclaration? = null) = buildSymbol {
    name = symbol
    declaration?.let { this.setProperty("decl", it.keyword) }
    namespace = "Foundation"
}

// Foundation symbols that are in Foundation on Apple but in FoundationNetworking on open-source Swift
// are rendered without any namespace.
//
// Note that URL, URLComponents, and URLQueryItem are part of Foundation on both platforms.
private fun builtInNetworkingSymbol(symbol: String, declaration: SwiftDeclaration? = null) = buildSymbol {
    name = symbol
    declaration?.let { this.setProperty("decl", it.keyword) }
}
