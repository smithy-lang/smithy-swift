//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension JSONStreamParser {

    func startString() throws -> Event {
        // Check the JSON stack to ensure this JSON value is expected / allowed
        // Then, update the next expected element
        try startJSONValue(index: input.characterIndex, isString: true)

        // This will hold the Swift string parsed out of the JSON string.
        var string = ""

        // Loop over the JSON data until an unescaped double quote,
        // which terminates the string.
        repeat {
            do {
                let block = String(data: try input.nextStringBlock(), encoding: input.encoding)
                block.map { string.append($0) }
                currentChar = try input.next()
                if currentChar.value < 32 {
                    // Character is a control character & is forbidden in JSON strings.
                    throw ParserError.controlCharacterInString(input.characterIndex)
                } else if currentChar == Self.backslash {
                    currentChar = try input.next()
                    switch currentChar {
                    case Self.doubleQuote:
                        // The sequence \" renders to a literal double quote.
                        string.append("\"")
                        currentChar = Unicode.Scalar(0)
                    case Self.backslash:
                        // The sequence \\ renders to a literal backslash.
                        string.append("\\")
                    case Self.forwardSlash:
                        // The sequence \/ renders to a literal forward slash.
                        string.append("/")
                    case Self.b:
                        // The sequence \b renders to a backspace control character. (ASCII 0x08)
                        string.append("\u{08}")
                    case Self.f:
                        // The sequence \f renders to a form-feed control character. (ASCII 0x0C)
                        string.append("\u{0C}")
                    case Self.n:
                        // The sequence \n renders to a linefeed control character (i.e. newline).
                        string.append("\n")
                    case Self.r:
                        // The sequence \r renders to a carriage return control character.
                        string.append("\r")
                    case Self.t:
                        // The sequence \t renders to a tab control character.
                        string.append("\t")
                    case Self.u:
                        // \u has been used to specify a Unicode character by hex code.

                        // Get the hex string-encoded code point.
                        let codePoint = try codePoint()

                        // Add the code point to the string data
                        string.append(String(codePoint))
                    default:
                        throw ParserError.unsupportedEscapeSequence(currentChar, input.characterIndex - 1)
                    }
                }
            } catch CharacterStreamControl.endOfJSON {
                // End of JSON before closing the string results in malformed JSON.
                throw ParserError.unexpectedEndOfJSON
            }
        } while currentChar != Self.doubleQuote

        // Return the parsed string as either an object key or as a value, as appropriate
        let expectedNext = stack.expectedNext()
        if expectedNext == .nameSeparator {
            return .key(string)
        } else {
            return .string(string)
        }
    }

    private func codePoint() throws -> Unicode.Scalar {

        // \u has already been detected and indexed past.  Decode the four hex digits.
        let group1 = try decodeFourHexDigits()

        if group1 >= 0xd800 && group1 <= 0xdbff {
            // Group1 is a "high surrogate" character.
            // Look for the "low surrogate" to be encoded next.

            // Expect another \u to follow.
            guard try input.next() == Self.backslash && input.next() == Self.u else {
                throw ParserError.missingLowSurrogate(input.characterIndex)
            }

            // Read the second hex value.
            let group2 = try decodeFourHexDigits()

            // Verify that this value is a valid low surrogate.
            guard group2 >= 0xdc00 && group2 <= 0xdfff else {
                throw ParserError.missingLowSurrogate(input.characterIndex)
            }

            // Convert the two surrogates to a character in the "Supplementary Multilingual Plane".
            let code: UInt32 = ((group1 - 0xd800) * 0x400) + (group2 - 0xdc00) + 0x10000
            guard let scalar = Unicode.Scalar(code) else {
                throw ParserError.unsupportedCodePoint(input.characterIndex)
            }
            return scalar
        } else {
            // This character is in the "Basic Multilingual Plane".  The value in the hex group is the code point.
            guard let scalar = Unicode.Scalar(group1) else {
                throw ParserError.unsupportedCodePoint(input.characterIndex)
            }
            return scalar
        }
    }

    private func decodeFourHexDigits() throws -> UInt32 {
        let hexDigit3 = try hexDigit()
        let hexDigit2 = try hexDigit()
        let hexDigit1 = try hexDigit()
        let hexDigit0 = try hexDigit()
        return (hexDigit3 << 12) + (hexDigit2 << 8) + (hexDigit1 << 4) + hexDigit0
    }

    private func hexDigit() throws -> UInt32 {
        currentChar = try input.next()
        if currentChar >= Self.zero && currentChar <= Self.nine {
            return UInt32(currentChar.value - Self.zero.value)
        } else if currentChar >= Self.A && currentChar <= Self.F {
            return UInt32(10 + currentChar.value - Self.A.value)
        } else if currentChar >= Self.a && currentChar <= Self.f {
            return UInt32(10 + currentChar.value - Self.a.value)
        } else {
            throw ParserError.invalidUnicodeCodePointDigit(currentChar, input.characterIndex)
        }
    }
}
