//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Locale
import struct Foundation.NSRange
import class Foundation.NSRegularExpression

extension String {

    /// Escapes special characters in the string, then surrounds it in double quotes
    /// to form a Swift string literal.
    var literal: String {
        let escaped = description
            .replacingOccurrences(of: "\0", with: "\\0")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\'", with: "\\'")
        return "\"\(escaped)\""
    }

    var inBackticks: String {
        "`\(self)`"
    }

    var capitalized: String {
        let firstChar = self.first?.uppercased() ?? ""
        return "\(firstChar)\(self.dropFirst())"
    }

    func toLowerCamelCase() -> String {
        let words = splitOnWordBoundaries() // Split into words
        let firstWord = words.first!.lowercased() // make first word lowercase
        return firstWord + words.dropFirst().joined() // join lowercased first word to remainder
    }

    func toUpperCamelCase() -> String {
        let words = splitOnWordBoundaries() // Split into words
        let firstLetter = words.first!.first!.uppercased() // make first letter uppercase
        return firstLetter + words.joined().dropFirst() // join uppercased first letter to remainder
    }

    private func splitOnWordBoundaries() -> [String] {
        // TODO: when nonsupporting platforms are dropped, convert this to Swift-native regex
        // adapted from Java v2 SDK CodegenNamingUtils.splitOnWordBoundaries
        var result = self

        // all non-alphanumeric characters: "acm-success"-> "acm success"
        result = nonAlphaNumericRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " ")

        // if there is an underscore, split on it: "acm_success" -> "acm", "_", "success"
        result = underscoreRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " _ ")

        // if a number has a standalone v or V in front of it, separate it out
        result = smallVRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 v$2")
        result = largeVRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 V$2")

        // add a space between camelCased words
        result = camelCaseSplitRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " ")

        // add a space after acronyms
        result = acronymSplitRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 $2")

        // add space after a number in the middle of a word
        result = spaceAfterNumberRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 $2")

        // remove extra spaces - multiple consecutive ones or those and the beginning/end of words
        result = removeExtraSpaceRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " ")
            .trimmingCharacters(in: .whitespaces)

        return result.components(separatedBy: " ")
    }

    private var range: NSRange {
        NSRange(location: 0, length: count)
    }
}

// Regexes used in splitOnWordBoundaries() above.
// force_try linter rule is disabled since these are just created from static strings.
// swiftlint:disable force_try
private let nonAlphaNumericRegex = try! NSRegularExpression(pattern: "[^A-Za-z0-9+_]")
private let underscoreRegex = try! NSRegularExpression(pattern: "_")
private let smallVRegex = try! NSRegularExpression(pattern: "([^a-z]{2,})v([0-9]+)")
private let largeVRegex = try! NSRegularExpression(pattern: "([^A-Z]{2,})V([0-9]+)")
private let camelCaseSplitRegex = try! NSRegularExpression(pattern: "(?<=[a-z])(?=[A-Z]([a-zA-Z]|[0-9]))")
private let acronymSplitRegex = try! NSRegularExpression(pattern: "([A-Z]+)([A-Z][a-z])")
private let spaceAfterNumberRegex = try! NSRegularExpression(pattern: "([0-9])([a-zA-Z])")
private let removeExtraSpaceRegex = try! NSRegularExpression(pattern: "\\s+")
// swiftlint:enable force_try
