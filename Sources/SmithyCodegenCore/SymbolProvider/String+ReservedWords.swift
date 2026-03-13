//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension String {

    /// Modifies Swift reserved words that are used in Smithy models so that they can be safely used as identifiers in rendered Swift.
    ///
    /// Taken from `ReservedWords.kt`:
    /// https://github.com/smithy-lang/smithy-swift/blob/main/smithy-swift-codegen/src/main/kotlin/software/amazon/smithy/swift/codegen/lang/ReservedWords.kt
    var escapingReservedWords: String {
        if self == "Protocol" || self == "Type" {
            // Swift metatypes
            "Model\(self)"
        } else if reservedWords.contains(self) {
            // Surround reserved words in backticks to force compiler
            // to treat them as identifiers
            self.inBackticks
        } else {
            self
        }
    }
}

private let reservedWords = [
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
    "package",
    "postfix",
    "prefix",
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
    "while",
]
