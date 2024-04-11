//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum SmithyTimestamps.TimestampFormat

public typealias ReadingClosure<T, Reader> = (Reader) throws -> T

public func mapReadingClosure<T, Reader: SmithyReader>(
    valueReadingClosure: @escaping ReadingClosure<T, Reader>,
    keyNodeInfo: Reader.NodeInfo,
    valueNodeInfo: Reader.NodeInfo,
    isFlattened: Bool
) -> ReadingClosure<[String: T], Reader> {
    return { reader in
        try reader.readMap(
            valueReadingClosure: valueReadingClosure,
            keyNodeInfo: keyNodeInfo,
            valueNodeInfo: valueNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func mapReadingClosure<T, Reader: SmithyReader>(
    valueReadingClosure: @escaping ReadingClosure<T, Reader>,
    keyNodeInfo: Reader.NodeInfo,
    valueNodeInfo: Reader.NodeInfo,
    isFlattened: Bool
) -> ReadingClosure<[String: T]?, Reader> {
    return { reader in
        try reader.readMapIfPresent(
            valueReadingClosure: valueReadingClosure,
            keyNodeInfo: keyNodeInfo,
            valueNodeInfo: valueNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func listReadingClosure<T, Reader: SmithyReader>(
    memberReadingClosure: @escaping ReadingClosure<T, Reader>,
    memberNodeInfo: Reader.NodeInfo,
    isFlattened: Bool
) -> ReadingClosure<[T], Reader> {
    return { reader in
        try reader.readList(
            memberReadingClosure: memberReadingClosure,
            memberNodeInfo: memberNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func listReadingClosure<T, Reader: SmithyReader>(
    memberReadingClosure: @escaping ReadingClosure<T, Reader>,
    memberNodeInfo: Reader.NodeInfo,
    isFlattened: Bool
) -> ReadingClosure<[T]?, Reader> {
    return { reader in
        try reader.readListIfPresent(
            memberReadingClosure: memberReadingClosure,
            memberNodeInfo: memberNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func timestampReadingClosure<Reader: SmithyReader>(format: TimestampFormat) -> ReadingClosure<Date, Reader> {
    return { reader in
        try reader.readTimestamp(format: format)
    }
}

public func timestampReadingClosure<Reader: SmithyReader>(format: TimestampFormat) -> ReadingClosure<Date?, Reader> {
    return { reader in
        try reader.readTimestampIfPresent(format: format)
    }
}

public extension String {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> String {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> String? {
        try reader.readIfPresent()
    }
}

public extension RawRepresentable where RawValue == Int {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Self {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Self? {
        try reader.readIfPresent()
    }
}

public extension RawRepresentable where RawValue == String {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Self {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Self? {
        try reader.readIfPresent()
    }
}

public extension Bool {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Bool {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Bool? {
        try reader.readIfPresent()
    }
}

public extension Int {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Int {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Int? {
        try reader.readIfPresent()
    }
}

public extension Float {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Float {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Float? {
        try reader.readIfPresent()
    }
}

public extension Double {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Double {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Double? {
        try reader.readIfPresent()
    }
}

public extension Data {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Data {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Data? {
        try reader.readIfPresent()
    }
}

public extension Document {

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Document {
        try reader.read()
    }

    static func read<Reader: SmithyReader>(from reader: Reader) throws -> Document? {
        try reader.readIfPresent()
    }
}
