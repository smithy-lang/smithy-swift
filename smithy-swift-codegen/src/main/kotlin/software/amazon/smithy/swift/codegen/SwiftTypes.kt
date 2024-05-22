/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.model.buildSymbol

object SwiftTypes {
    val String = builtInSymbol("String")
    val Int = builtInSymbol("Int")
    val Int8 = builtInSymbol("Int8")
    val Int16 = builtInSymbol("Int16")
    val Float = builtInSymbol("Float")
    val Double = builtInSymbol("Double")
    val Bool = builtInSymbol("Bool")

    val StringArray = builtInSymbol("Array<Swift.String>")

    val List = builtInSymbol("List")
    val Set = builtInSymbol("Set")
    val Map = builtInSymbol("Map")
    val Error = builtInSymbol("Error")

    object Protocols {
        val Equatable = builtInSymbol("Equatable")
        val Hashable = builtInSymbol("Hashable")
        val RawRepresentable = builtInSymbol("RawRepresentable")
        val CaseIterable = builtInSymbol("CaseIterable")
        val CustomDebugStringConvertible = builtInSymbol("CustomDebugStringConvertible")
    }
}

private fun builtInSymbol(symbol: String) = buildSymbol {
    name = symbol
    namespace = "Swift"
}
