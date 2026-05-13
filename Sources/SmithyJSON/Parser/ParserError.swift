//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum ParserError: LocalizedError {
    case unexpectedEndOfObject
    case unexpectedObjectKey(Int)
    case unexpectedEndOfArray
    case unexpectedNameSeparator(Int)
    case unexpectedValueSeparator(Int)
    case unexpectedToken(Int)
    case extraRootElement
    case terminatingSeparator
    case unexpectedCharacter(Unicode.Scalar, Int)
    case unexpectedEndOfJSON
    case invalidUTF8(Int)
    case unsupportedEscapeSequence(Unicode.Scalar, Int)
    case invalidUnicodeCodePointDigit(Unicode.Scalar, Int)
    case missingLowSurrogate(Int)
    case unsupportedCodePoint(Int)
    case controlCharacterInString(Int)
    case unseparatedElement(Int)
    case unterminatedString
    case unexpectedEndOfNumber(Int)
    case unexpectedNilIndex

    public var errorDescription: String? {
        switch self {
            case .unexpectedEndOfObject:
            return "unexpectedEndOfObject"
        case .unexpectedObjectKey(let index):
            return "unexpectedObjectKey: at \(index)"
        case .unexpectedEndOfArray:
            return "unexpectedEndOfArray"
        case .unexpectedNameSeparator(let index):
            return "unexpectedNameSeparator: at \(index)"
        case .unexpectedValueSeparator(let index):
            return "unexpectedValueSeparator: at \(index)"
        case .unexpectedToken(let index):
            return "unexpectedToken: at \(index)"
            case .extraRootElement:
            return "extraRootElement"
        case .terminatingSeparator:
            return "terminatingSeparator"
        case .unexpectedCharacter(let code, let index):
            return "unexpectedCharacter: \(String(code)) at \(index)"
        case .unexpectedEndOfJSON:
            return "unexpectedEndOfJSON"
        case .invalidUTF8(let index):
            return "invalidUTF8: at \(index)"
        case .unsupportedEscapeSequence(let code, let index):
            return "unsupportedEscapeSequence: \\\(String(code)) at \(index)"
        case .invalidUnicodeCodePointDigit(let code, let index):
            return "invalidUnicodeCodePointDigit: \\\(String(code)) at \(index)"
        case .missingLowSurrogate(let index):
            return "missingLowSurrogate: at \(index)"
        case .unsupportedCodePoint(let index):
            return "unsupportedCodePoint: at \(index)"
        case .controlCharacterInString(let index):
            return "controlCharacterInString: at \(index)"
        case .unseparatedElement(let index):
            return "unseparatedElement: at \(index)"
        case .unterminatedString:
            return "unterminatedString"
        case .unexpectedEndOfNumber(let index):
            return "unexpectedEndOfNumber: at \(index)"
        case .unexpectedNilIndex:
            return "unexpectedNilIndex"
        }
    }
}
