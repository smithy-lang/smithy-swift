//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Foundation

/// Options set on the top-level encoder to pass down the encoding hierarchy.
public struct XMLEncoderOptions {
    public var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
    public var dataEncodingStrategy: DataEncodingStrategy = .base64
    public var nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy = .throw
    public var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
    public var nodeEncodingStrategy: NodeEncodingStrategy = .deferredToEncoder
    public var stringEncodingStrategy: StringEncodingStrategy = .deferredToString
    public var outputFormatting: OutputFormatting = .sortedKeys
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public var rootKey:String? = nil
    public var rootAttributes: [String: String]? = nil
    public var header: XMLHeader? = nil
    
    public init(dateEncodingStrategy: DateEncodingStrategy = .deferredToDate,
         dataEncodingStrategy: DataEncodingStrategy = .base64,
         nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy = .throw,
         keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys,
         nodeEncodingStrategy: NodeEncodingStrategy = .deferredToEncoder,
         stringEncodingStrategy: StringEncodingStrategy = .deferredToString,
         outputFormatting: OutputFormatting = .sortedKeys,
         userInfo: [CodingUserInfoKey: Any] = [:],
         rootKey:String? = nil,
         rootAttributes: [String: String]? = nil,
         header: XMLHeader? = nil) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
        self.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.nodeEncodingStrategy = nodeEncodingStrategy
        self.stringEncodingStrategy = stringEncodingStrategy
        self.outputFormatting = outputFormatting
        self.userInfo = userInfo
        self.rootKey = rootKey
        self.rootAttributes = rootAttributes
        self.header = header
    }
}

/// The formatting of the output XML data.
public struct OutputFormatting: OptionSet {
    /// The format's default value.
    public let rawValue: UInt

    /// Creates an OutputFormatting value with the given raw value.
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Produce human-readable XML with indented output.
    public static let prettyPrinted = OutputFormatting(rawValue: 1 << 0)

    /// Produce XML with keys sorted in lexicographic order.
    public static let sortedKeys = OutputFormatting(rawValue: 1 << 1)
}

/// A node's encoding type
public enum NodeEncoding {
    case attribute
    case element
    case both

    public static let `default`: NodeEncoding = .element
}

/// The strategy to use for encoding `Date` values.
public enum DateEncodingStrategy {
    /// Defer to `Date` for choosing an encoding. This is the default strategy.
    case deferredToDate

    /// Encode the `Date` as a UNIX timestamp (as a XML number).
    case secondsSince1970

    /// Encode the `Date` as UNIX millisecond timestamp (as a XML number).
    case millisecondsSince1970

    /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    case iso8601

    /// Encode the `Date` as a string formatted by the given formatter.
    case formatted(DateFormatter)

    /// Encode the `Date` as a custom value encoded by the given closure.
    ///
    /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
    case custom((Date, Encoder) throws -> ())
}

/// The strategy to use for encoding `String` values.
public enum StringEncodingStrategy {
    /// Defer to `String` for choosing an encoding. This is the default strategy.
    case deferredToString

    /// Encode the `String` as a CData-encoded string.
    case cdata
}

/// The strategy to use for encoding `Data` values.
public enum DataEncodingStrategy {
    /// Defer to `Data` for choosing an encoding.
    case deferredToData

    /// Encoded the `Data` as a Base64-encoded string. This is the default strategy.
    case base64

    /// Encode the `Data` as a custom value encoded by the given closure.
    ///
    /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
    case custom((Data, Encoder) throws -> ())
}

/// The strategy to use for non-XML-conforming floating-point values (IEEE 754 infinity and NaN).
public enum NonConformingFloatEncodingStrategy {
    /// Throw upon encountering non-conforming values. This is the default strategy.
    case `throw`

    /// Encode the values using the given representation strings.
    case convertToString(positiveInfinity: String, negativeInfinity: String, nan: String)
}

/// The strategy to use for automatically changing the value of keys before encoding.
public enum KeyEncodingStrategy {
    /// Use the keys specified by each type. This is the default strategy.
    case useDefaultKeys

    /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to XML payload.
    ///
    /// Capital characters are determined by testing membership in
    /// `CharacterSet.uppercaseLetters` and `CharacterSet.lowercaseLetters`
    /// (Unicode General Categories Lu and Lt).
    /// The conversion to lower case uses `Locale.system`, also known as
    /// the ICU "root" locale. This means the result is consistent
    /// regardless of the current user's locale and language preferences.
    ///
    /// Converting from camel case to snake case:
    /// 1. Splits words at the boundary of lower-case to upper-case
    /// 2. Inserts `_` between words
    /// 3. Lowercases the entire string
    /// 4. Preserves starting and ending `_`.
    ///
    /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
    ///
    /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
    case convertToSnakeCase

    /// Same as convertToSnakeCase, but using `-` instead of `_`
    /// For example, `oneTwoThree` becomes `one-two-three`.
    case convertToKebabCase

    /// Capitalize the first letter only
    /// `oneTwoThree` becomes  `OneTwoThree`
    case capitalized

    /// Uppercase ize all letters
    /// `oneTwoThree` becomes  `ONETWOTHREE`
    case uppercased

    /// Lowercase all letters
    /// `oneTwoThree` becomes  `onetwothree`
    case lowercased

    /// Provide a custom conversion to the key in the encoded XML from the
    /// keys specified by the encoded types.
    /// The full path to the current encoding position is provided for
    /// context (in case you need to locate this key within the payload).
    /// The returned key is used in place of the last component in the
    /// coding path before encoding.
    /// If the result of the conversion is a duplicate key, then only one
    /// value will be present in the result.
    case custom((_ codingPath: [CodingKey]) -> CodingKey)

    static func _convertToSnakeCase(_ stringKey: String) -> String {
        return _convert(stringKey, usingSeparator: "_")
    }

    static func _convertToKebabCase(_ stringKey: String) -> String {
        return _convert(stringKey, usingSeparator: "-")
    }

    static func _convert(_ stringKey: String, usingSeparator separator: String) -> String {
        guard !stringKey.isEmpty else {
            return stringKey
        }

        var words: [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on
        // transition from lower to upper case, then on transition of >1
        // upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

        // Find next uppercase character
        while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }

            // Is the next lowercase letter more than 1 after the uppercase?
            // If so, we encountered a group of uppercase letters that we
            // should treat as its own word
            let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result = words.map { range in
            stringKey[range].lowercased()
        }.joined(separator: separator)
        return result
    }

    static func _convertToCapitalized(_ stringKey: String) -> String {
        return stringKey.capitalizingFirstLetter()
    }

    static func _convertToLowercased(_ stringKey: String) -> String {
        return stringKey.lowercased()
    }

    static func _convertToUppercased(_ stringKey: String) -> String {
        return stringKey.uppercased()
    }
}

@available(*, deprecated, renamed: "NodeEncodingStrategy")
public typealias NodeEncodingStrategies = NodeEncodingStrategy

public typealias XMLNodeEncoderClosure = ((CodingKey) -> NodeEncoding)
public typealias XMLEncodingClosure = (Encodable.Type, Encoder) -> XMLNodeEncoderClosure

/// Set of strategies to use for encoding of nodes.
public enum NodeEncodingStrategy {
    /// Defer to `Encoder` for choosing an encoding. This is the default strategy.
    case deferredToEncoder

    /// Return a closure computing the desired node encoding for the value by its coding key.
    case custom(XMLEncodingClosure)

    func nodeEncodings(
        forType codableType: Encodable.Type,
        with encoder: Encoder
    ) -> ((CodingKey) -> NodeEncoding) {
        return encoderClosure(codableType, encoder)
    }

    var encoderClosure: XMLEncodingClosure {
        switch self {
        case .deferredToEncoder: return NodeEncodingStrategy.defaultEncoder
        case let .custom(closure): return closure
        }
    }

    static let defaultEncoder: XMLEncodingClosure = { codableType, _ in
        guard let dynamicType = codableType as? DynamicNodeEncoding.Type else {
            return { _ in .default }
        }
        return dynamicType.nodeEncoding(for:)
    }
}
