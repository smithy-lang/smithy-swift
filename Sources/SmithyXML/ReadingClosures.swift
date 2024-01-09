//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import typealias SmithyReadWrite.ReadingClosure
import enum SmithyTimestamps.TimestampFormat

public func mapReadingClosure<T>(
    valueReadingClosure: @escaping ReadingClosure<T, Reader>,
    keyNodeInfo: NodeInfo,
    valueNodeInfo: NodeInfo,
    isFlattened: Bool
) -> ReadingClosure<[String: T]?, Reader> {
    return { reader in
        try reader.readMap(
            valueReadingClosure: valueReadingClosure,
            keyNodeInfo: keyNodeInfo,
            valueNodeInfo: valueNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func listReadingClosure<T>(
    memberReadingClosure: @escaping ReadingClosure<T, Reader>,
    memberNodeInfo: NodeInfo,
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

public func timestampReadingClosure(format: TimestampFormat) -> ReadingClosure<Date, Reader> {
    return { reader in
        try reader.readTimestamp(format: format)
    }
}

public extension String {

    static func readingClosure(from reader: Reader) throws -> String? {
        try reader.read()
    }
}

public extension RawRepresentable where RawValue == Int {

    static func readingClosure(from reader: Reader) throws -> Self? {
        try reader.read()
    }
}

public extension RawRepresentable where RawValue == String {

    static func readingClosure(from reader: Reader) throws -> Self? {
        try reader.read()
    }
}

public extension Bool {

    static func readingClosure(from reader: Reader) throws -> Bool? {
        try reader.read()
    }
}

public extension Int {

    static func readingClosure(from reader: Reader) throws -> Int? {
        try reader.read()
    }
}

public extension Float {

    static func readingClosure(from reader: Reader) throws -> Float? {
        try reader.read()
    }
}

public extension Double {

    static func readingClosure(from reader: Reader) throws -> Double? {
        try reader.read()
    }
}

