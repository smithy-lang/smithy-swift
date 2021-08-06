package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.model.buildSymbol

object SwiftTypes {
    val String: Symbol = builtInSymbol("String")
    val Int: Symbol = builtInSymbol("Int")
    val Int8: Symbol = builtInSymbol("Int8")
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

    object Protocols {
        val Equatable: Symbol = builtInSymbol("Equatable")
        val Hashable: Symbol = builtInSymbol("Hashable")
    }
}

private fun builtInSymbol(symbol: String): Symbol = buildSymbol {
    name = symbol
    namespace = "Swift"
    nullable = false
}