//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import protocol Smithy.Document
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat

@_spi(SmithyReadWrite)
public typealias ReadingClosure<T, Reader> = (Reader) throws -> T

@_spi(SmithyReadWrite)
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

@_spi(SmithyReadWrite)
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

@_spi(SmithyReadWrite)
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

@_spi(SmithyReadWrite)
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

@_spi(SmithyReadWrite)
public func timestampReadingClosure<Reader: SmithyReader>(format: TimestampFormat) -> ReadingClosure<Date, Reader> {
    return { reader in
        try reader.readTimestamp(format: format)
    }
}

@_spi(SmithyReadWrite)
public func timestampReadingClosure<Reader: SmithyReader>(format: TimestampFormat) -> ReadingClosure<Date?, Reader> {
    return { reader in
        try reader.readTimestampIfPresent(format: format)
    }
}

@_spi(SmithyReadWrite)
public struct ReadingClosureBox<Value: RawRepresentable> {

    public init() {}

    public func read<Reader: SmithyReader>(from reader: Reader) throws -> Value where Value.RawValue == Int {
        try reader.read()
    }

    public func read<Reader: SmithyReader>(from reader: Reader) throws -> Value? where Value.RawValue == Int {
        try reader.readIfPresent()
    }

    public func read<Reader: SmithyReader>(from reader: Reader) throws -> Value where Value.RawValue == String {
        try reader.read()
    }

    public func read<Reader: SmithyReader>(from reader: Reader) throws -> Value? where Value.RawValue == String {
        try reader.readIfPresent()
    }
}

@_spi(SmithyReadWrite)
public enum ReadingClosures {

    public static func readString<Reader: SmithyReader>(from reader: Reader) throws -> String {
        try reader.read()
    }

    public static func readString<Reader: SmithyReader>(from reader: Reader) throws -> String? {
        try reader.readIfPresent()
    }

    public static func readBool<Reader: SmithyReader>(from reader: Reader) throws -> Bool {
        try reader.read()
    }

    public static func readBool<Reader: SmithyReader>(from reader: Reader) throws -> Bool? {
        try reader.readIfPresent()
    }

    public static func readInt<Reader: SmithyReader>(from reader: Reader) throws -> Int {
        try reader.read()
    }

    public static func readInt<Reader: SmithyReader>(from reader: Reader) throws -> Int? {
        try reader.readIfPresent()
    }

    public static func readInt8<Reader: SmithyReader>(from reader: Reader) throws -> Int8 {
        try reader.read()
    }

    public static func readInt8<Reader: SmithyReader>(from reader: Reader) throws -> Int8? {
        try reader.readIfPresent()
    }

    public static func readInt16<Reader: SmithyReader>(from reader: Reader) throws -> Int16 {
        try reader.read()
    }

    public static func readInt16<Reader: SmithyReader>(from reader: Reader) throws -> Int16? {
        try reader.readIfPresent()
    }

    public static func readFloat<Reader: SmithyReader>(from reader: Reader) throws -> Float {
        try reader.read()
    }

    public static func readFloat<Reader: SmithyReader>(from reader: Reader) throws -> Float? {
        try reader.readIfPresent()
    }

    public static func readDouble<Reader: SmithyReader>(from reader: Reader) throws -> Double {
        try reader.read()
    }

    public static func readDouble<Reader: SmithyReader>(from reader: Reader) throws -> Double? {
        try reader.readIfPresent()
    }

    public static func readData<Reader: SmithyReader>(from reader: Reader) throws -> Data {
        try reader.read()
    }

    public static func readData<Reader: SmithyReader>(from reader: Reader) throws -> Data? {
        try reader.readIfPresent()
    }

    public static func readDocument<Reader: SmithyReader>(from reader: Reader) throws -> Document {
        try reader.read()
    }

    public static func readDocument<Reader: SmithyReader>(from reader: Reader) throws -> Document? {
        try reader.readIfPresent()
    }
}

@_spi(SmithyReadWrite)
public func optionalFormOf<T, Reader: SmithyReader>(
    readingClosure: @escaping ReadingClosure<T, Reader>
) -> ReadingClosure<T?, Reader> {
    return { reader in
        do {
            return try readingClosure(reader)
        } catch ReaderError.requiredValueNotPresent {
            return nil
        }
    }
}
