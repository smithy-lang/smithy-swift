/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.lang

import software.amazon.smithy.codegen.core.ReservedWords
import software.amazon.smithy.codegen.core.ReservedWordsBuilder

val swiftReservedWords: ReservedWords by lazy {
    ReservedWordsBuilder()
        .apply {
            reservedWords.forEach {
                if (metaTypes.contains(it)) {
                    put(it, "Model$it")
                } else {
                    put(it, "`$it`")
                }
            }
        }.build()
}

val reservedWords = listOf(
    "Any",
    "#available",
    "associatedtype",
    "associativity",
    "as",
    "break",
    "case",
    "catch",
    "class",
    "#colorLiteral",
    "#column",
    "continue",
    "convenience",
    "deinit",
    "default",
    "defer",
    "didSet",
    "do",
    "dynamic",
    "enum",
    "extension",
    "else",
    "#else",
    "#elseif",
    "#endif",
    "#error",
    "fallthrough",
    "false",
    "#file",
    "#fileLiteral",
    "fileprivate",
    "final",
    "for",
    "func",
    "#function",
    "get",
    "guard",
    "indirect",
    "infix",
    "if",
    "#if",
    "#imageLiteral",
    "in",
    "is",
    "import",
    "init",
    "inout",
    "internal",
    "lazy",
    "left",
    "let",
    "#line",
    "mutating",
    "none",
    "nonmutating",
    "nil",
    "open",
    "operator",
    "optional",
    "override",
    "postfix",
    "private",
    "protocol",
    "Protocol",
    "public",
    "repeat",
    "rethrows",
    "return",
    "required",
    "right",
    "#selector",
    "self",
    "Self",
    "set",
    "#sourceLocation",
    "super",
    "static",
    "struct",
    "subscript",
    "switch",
    "this",
    "throw",
    "throws",
    "true",
    "try",
    "Type",
    "typealias",
    "unowned",
    "var",
    "#warning",
    "weak",
    "willSet",
    "where",
    "while"
)

val metaTypes = listOf(
    "Protocol",
    "Type"
)
