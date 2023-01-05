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
    val Int32 = builtInSymbol("Int32")
    val Int64 = builtInSymbol("Int64")
    val UInt = builtInSymbol("UInt")
    val UInt8 = builtInSymbol("UInt8")
    val UInt32 = builtInSymbol("UInt32")
    val UInt64 = builtInSymbol("UInt64")
    val Float = builtInSymbol("Float")
    val Double = builtInSymbol("Double")
    val Bool = builtInSymbol("Bool")
    val TimeInterval = builtInSymbol("TimeInterval")

    val List = builtInSymbol("List")
    val Set = builtInSymbol("Set")
    val Map = builtInSymbol("Map")
    val Error = builtInSymbol("Error")
    val Result = builtInSymbol("Result")
    val Decoder = builtInSymbol("Decoder")
    val Encoder = builtInSymbol("Encoder")
    val CodingKey = builtInSymbol("CodingKey")
    val DecodingError = builtInSymbol("DecodingError")

    object Protocols {
        val Equatable = builtInSymbol("Equatable")
        val Hashable = builtInSymbol("Hashable")
        val RawRepresentable = builtInSymbol("RawRepresentable")
        val Codable = builtInSymbol("Codable")
        val Encodable = builtInSymbol("Encodable")
        val Decodable = builtInSymbol("Decodable")
        val CaseIterable = builtInSymbol("CaseIterable")
        val CustomDebugStringConvertible = builtInSymbol("CustomDebugStringConvertible")
    }
}

private fun builtInSymbol(symbol: String) = buildSymbol {
    name = symbol
    namespace = "Swift"
}
