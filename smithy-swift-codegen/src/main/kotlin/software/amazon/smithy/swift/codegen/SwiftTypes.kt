package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.model.buildSymbol

object SwiftTypes {
    val String: Symbol = builtInSymbol("String")
    val Int: Symbol = builtInSymbol("Int")
    val Int8: Symbol = builtInSymbol("Int8")
    val Int16: Symbol = builtInSymbol("Int16")
    val Int32: Symbol = builtInSymbol("Int32")
    val Int64: Symbol = builtInSymbol("Int64")
    val UInt: Symbol = builtInSymbol("UInt")
    val UInt8: Symbol = builtInSymbol("UInt8")
    val UInt32: Symbol = builtInSymbol("UInt32")
    val UInt64: Symbol = builtInSymbol("UInt64")
    val Float: Symbol = builtInSymbol("Float")
    val Double: Symbol = builtInSymbol("Double")
    val Bool: Symbol = builtInSymbol("Bool")

    val List: Symbol = builtInSymbol("List")
    val Set: Symbol = builtInSymbol("Set")
    val Map: Symbol = builtInSymbol("Map")
    val Error: Symbol = builtInSymbol("Error")
    val Result: Symbol = builtInSymbol("Result")
    val Decoder: Symbol = builtInSymbol("Decoder")
    val Encoder: Symbol = builtInSymbol("Encoder")
    val CodingKey: Symbol = builtInSymbol("CodingKey")
    val CheckedContinuation: Symbol = builtInSymbol("CheckedContinuation")
    val DecodingError: Symbol = builtInSymbol("DecodingError")

    object Protocols {
        val Equatable: Symbol = builtInSymbol("Equatable")
        val Hashable: Symbol = builtInSymbol("Hashable")
        val RawRepresentable: Symbol = builtInSymbol("RawRepresentable")
        val Codable: Symbol = builtInSymbol("Codable")
        val Encodable: Symbol = builtInSymbol("Encodable")
        val Decodable: Symbol = builtInSymbol("Decodable")
        val Reflection: Symbol = builtInSymbol("Reflection")
        val CaseIterable: Symbol = builtInSymbol("CaseIterable")
        val CustomDebugStringConvertible: Symbol = builtInSymbol("CustomDebugStringConvertible")
    }
}

private fun builtInSymbol(symbol: String): Symbol = buildSymbol {
    name = symbol
    namespace = "Swift"
    nullable = false
}
