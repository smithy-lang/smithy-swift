//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

struct CharacterStream {

    private let data: Data
    private var dataIndex: Data.Index
    private(set) var characterIndex = -1

    init(data: Data) {
        self.data = data
        self.dataIndex = data.startIndex
    }

    var encoding: String.Encoding { .utf8 }

    mutating func nextIf(predicate: (Unicode.Scalar) -> Bool) throws -> Unicode.Scalar {
        let originalDataIndex = dataIndex
        let originalCharacterIndex = characterIndex
        let scalar = try next()
        if !predicate(scalar) {
            dataIndex = originalDataIndex
            characterIndex = originalCharacterIndex
        }
        return scalar
    }

    func isNull() -> Bool {
        var index = dataIndex
        while [JSONStreamParser.space, JSONStreamParser.tab, JSONStreamParser.carriageReturn, JSONStreamParser.lineFeed, JSONStreamParser.colon, JSONStreamParser.comma].contains(UnicodeScalar(data[index])) {
            index += 1
        }
        if !data.indices.contains(index.advanced(by: 3)) {
            return false
        }
        return UnicodeScalar(data[index]) == JSONStreamParser.n &&
            UnicodeScalar(data[index + 1]) == JSONStreamParser.u &&
            UnicodeScalar(data[index + 2]) == JSONStreamParser.l &&
            UnicodeScalar(data[index + 3]) == JSONStreamParser.l
    }

    // Gets the next Unicode character from the input, and advances the index.
    // Depending on the encoding, a character may be 1-4 bytes of the input.
    mutating func next() throws -> Unicode.Scalar {
        // Throw if there are no more bytes remaining.
        if dataIndex >= data.endIndex { throw CharacterStreamControl.endOfJSON }

        if data[dataIndex] & 0x80 == 0x00 {
            // A byte value with a zero in the most significant bit is a one-byte UTF-8 character.
            let scalar = Unicode.Scalar(data[dataIndex] & 0x7F)
            dataIndex += 1
            characterIndex += 1
            return scalar
        } else if data[dataIndex] & 0xE0 == 0xC0 {
            // A byte value with 110 in the most significant bits starts a 2-byte UTF-8 character.
            let scalar = UnicodeScalar(
                UInt32(data[dataIndex] & 0x1F) << 6
                | UInt32(data[dataIndex + 1] & 0x3F)
            )
            dataIndex += 2
            characterIndex += 1
            return scalar ?? JSONStreamParser.replacement
        } else if data[dataIndex] & 0xF0 == 0xE0 && dataIndex + 2 < data.endIndex {
            // A byte value with 1110 in the most significant bits starts a 3-byte UTF-8 character.
            let scalar = Unicode.Scalar(
                UInt32(data[dataIndex] & 0x0F) << 12
                | UInt32(data[dataIndex + 1] & 0x3F) << 6
                | UInt32(data[dataIndex + 2] & 0x3F)
            )
            dataIndex += 3
            characterIndex += 1
            return scalar ?? JSONStreamParser.replacement
        } else if data[dataIndex] & 0xF8 == 0xF0 && dataIndex + 3 < data.endIndex {
            // A byte value with 11110 in the most significant bits starts a 4-byte UTF-8 character.
            let scalar = Unicode.Scalar(
                UInt32(data[dataIndex] & 0x07) << 18
                | UInt32(data[dataIndex + 1] & 0x3F) << 12
                | UInt32(data[dataIndex + 2] & 0x3F) << 6
                | UInt32(data[dataIndex + 3] & 0x3F)
            )
            dataIndex += 4
            characterIndex += 1
            return scalar ?? JSONStreamParser.replacement
        } else {
            throw ParserError.invalidUTF8(dataIndex)
        }
    }

    // Must return data containing all encoded characters until '\' or '"' are reached.
    mutating func nextStringBlock() throws -> Data {
        let startIndex = dataIndex
        var endIndex = dataIndex
        var currentScalar = try next()
        while currentScalar != JSONStreamParser.backslash && currentScalar != JSONStreamParser.doubleQuote && currentScalar.value >= 32 {
            endIndex = dataIndex
            currentScalar = try next()
        }
        dataIndex = endIndex
        characterIndex -= 1
        return data[startIndex..<endIndex]
    }
}

enum CharacterStreamControl: Error {
    // This error is thrown when the stream is read,
    // but there are no further bytes remaining in the input.
    case endOfJSON
}
