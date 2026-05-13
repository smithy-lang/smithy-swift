//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Decimal

public enum Event {
    case startObject
    case key(String)
    case endObject
    case startList
    case endList
    case number(Decimal)
    case boolean(Bool)
    case string(String)
    case null
}

public class JSONStreamParser {
    var input: CharacterStream
    var currentChar = Unicode.Scalar(0)!
    var stack = ExpectedNextStack()
    var indexStack: [Int] = []

    public init(input: Data) {
        self.input = CharacterStream(data: input)
    }

    public func parse() throws -> Event {
        currentChar = try input.next()
        let event: Event
        // Skip over any whitespace
        while [Self.tab, Self.lineFeed, Self.carriageReturn, Self.space, Self.comma, Self.colon].contains(currentChar) {
            if currentChar == Self.comma {
                // Comma to separate array elements, or to separate object key-value pairs.
                try valueSeparator()
            }
            if currentChar == Self.colon {
                // Colon to separate object keys from their values.
                try nameSeparator()
            }
            currentChar = try input.next()
        }
        event = switch currentChar {
        case Self.openCurlyBracket:
            // Open curly bracket to open an object.
            try startObject()
        case Self.closeCurlyBracket:
            // Closing curly bracket to close an object.
            try endObject()
        case Self.openSquareBracket:
            // Opening square bracket to open an array.
            try startArray()
        case Self.closeSquareBracket:
            // Closing square bracket to close an array.
            try endArray()
        case Self.doubleQuote:
            // Double quote to start a string.
            try startString()
        case Self.minus, Self.zero...Self.nine:
            // Digit or minus sign starts a number.
            try startNumber()
        case Self.f:
            // The start of the word 'false' was detected.
            try startFalse()
        case Self.n:
            // The start of the word 'null' was detected.
            try startNull()
        case Self.t:
            // The start of the word 'true' was detected.
            try startTrue()
        default:
            // Some other token was detected; this is unallowed.
            throw ParserError.unexpectedCharacter(currentChar, input.characterIndex)
        }
        return event
    }

    public func parseToNextElement() throws {
        let event = try parse()
        switch event {
        case .startList:
            var listCount = 1
            while listCount > 0 {
                switch try parse() {
                case .startList:
                    listCount += 1
                case .endList:
                    listCount -= 1
                default:
                    break
                }
            }
        case .startObject:
            var objectCount = 1
            while objectCount > 0 {
                switch try parse() {
                case .startObject:
                    objectCount += 1
                case .endObject:
                    objectCount -= 1
                default:
                    break
                }
            }
        default:
            break
        }
    }

    public func isNull() -> Bool {
        input.isNull()
    }

    private func startObject() throws -> Event {
        // Check the JSON stack to ensure this JSON value is expected / allowed
        // Then, update the next expected element
        try startJSONValue(index: input.characterIndex, isString: false)

        stack.push(.objectEndOrKey)
        return .startObject
    }

    private func endObject() throws -> Event {
        let expectedNext = stack.expectedNext()

        // If an object key is the only thing expected next, then there was a value
        // separator (comma) just before end-of-object.
        // Throw since JSON forbids terminating separators.
        if expectedNext == .objectKey {
            throw ParserError.terminatingSeparator
        }
        guard expectedNext == .objectEndOrKey || expectedNext == .valueSeparatorOrObjectEnd else {
            throw ParserError.unexpectedEndOfObject
        }
        stack.pop()
        return .endObject
    }

    private func startArray() throws -> Event {
        // Check the JSON stack to ensure this JSON value is expected / allowed
        // Then, update the next expected element
        try startJSONValue(index: input.characterIndex, isString: false)

        stack.push(.arrayEndOrElement)
        indexStack.append(0)
        return .startList
    }

    private func endArray() throws -> Event {
        let expectedNext = stack.expectedNext()

        // If an array element is the only thing expected next, then there was a value
        // separator (comma) just before end-of-array.
        // Throw since JSON forbids terminating separators.
        if expectedNext == .arrayElement {
            throw ParserError.terminatingSeparator
        }
        guard expectedNext == .arrayEndOrElement || expectedNext == .valueSeparatorOrArrayEnd else {
            throw ParserError.unexpectedEndOfArray
        }
        stack.pop()
        _ = indexStack.popLast()
        return .endList
    }

    private func valueSeparator() throws {
        let expectedNext = stack.expectedNext()
        if expectedNext == .valueSeparatorOrObjectEnd {
            stack.replace(.objectKey)
        } else if expectedNext == .valueSeparatorOrArrayEnd {
            stack.replace(.arrayElement)
            indexStack.indices.last.map { indexStack[$0] += 1 }
        } else {
            throw ParserError.unexpectedValueSeparator(input.characterIndex)
        }
    }

    private func nameSeparator() throws {
        let expectedNext = stack.expectedNext()
        if expectedNext == .nameSeparator {
            stack.replace(.objectValue)
        } else {
            throw ParserError.unexpectedNameSeparator(input.characterIndex)
        }
    }

    private func startFalse() throws -> Event {
        let characterIndex = input.characterIndex
        guard try input.next() == Self.a && input.next() == Self.l && input.next() == Self.s && input.next() == Self.e else {
            throw ParserError.unexpectedToken(characterIndex)
        }

        // Check the JSON stack to ensure this JSON value is expected / allowed
        // Then, update the next expected element
        try startJSONValue(index: characterIndex, isString: false)
        return .boolean(false)
    }

    private func startNull() throws -> Event {
        let characterIndex = input.characterIndex
        guard try input.next() == Self.u && input.next() == Self.l && input.next() == Self.l else {
            throw ParserError.unexpectedToken(characterIndex)
        }

        // Check the JSON stack to ensure this JSON value is expected / allowed
        // Then, update the next expected element
        try startJSONValue(index: characterIndex, isString: false)
        return .null
    }

    private func startTrue() throws -> Event {
        let characterIndex = input.characterIndex
        guard try input.next() == Self.r && input.next() == Self.u && input.next() == Self.e else {
            throw ParserError.unexpectedToken(characterIndex)
        }

        // Check the JSON stack to ensure this JSON value is expected / allowed
        // Then, update the next expected element
        try startJSONValue(index: characterIndex, isString: false)
        return .boolean(true)
    }

    func startJSONValue(index: Int, isString: Bool) throws {
        try rootElementCheck()
        try arrayElementCheck()
        if !isString { try throwIfObjectKey(index: index) }
        try updateNextExpected(index: index)
    }

    private func rootElementCheck() throws {
        let expectedNext = stack.expectedNext()
        if expectedNext == .firstElement {
            stack.replace(.nothing)
        } else if expectedNext == .nothing {
            throw ParserError.extraRootElement
        }
    }

    private func arrayElementCheck() throws {
        let expectedNext = stack.expectedNext()
        if expectedNext == .arrayElement || expectedNext == .arrayEndOrElement {
            guard indexStack.last != nil else { throw ParserError.unexpectedNilIndex }
        }
    }

    private func updateNextExpected(index: Int) throws {
        let expectedNext = stack.expectedNext()
        if expectedNext == .valueSeparatorOrArrayEnd || expectedNext == .valueSeparatorOrObjectEnd {
            throw ParserError.unseparatedElement(index)
        } else if expectedNext == .nameSeparator {
            throw ParserError.unseparatedElement(index)
        } else if expectedNext == .arrayElement || expectedNext == .arrayEndOrElement {
            stack.replace(.valueSeparatorOrArrayEnd)
        } else if expectedNext == .objectKey || expectedNext == .objectEndOrKey {
            stack.replace(.nameSeparator)
        } else if expectedNext == .objectValue {
            stack.replace(.valueSeparatorOrObjectEnd)
        }
    }

    private func throwIfObjectKey(index: Int) throws {
        let expectedNext = stack.expectedNext()
        guard expectedNext != .objectKey && expectedNext != .objectEndOrKey else {
            throw ParserError.unexpectedObjectKey(index)
        }
    }
}
