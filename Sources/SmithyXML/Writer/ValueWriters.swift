//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import enum SmithyTimestamps.TimestampFormat

public typealias WriterClosure<T> = (T?, Writer) throws -> Void

public func mapWriter<T>(valueWriter: @escaping WriterClosure<T>, keyNodeInfo: NodeInfo, valueNodeInfo: NodeInfo, isFlattened: Bool) -> WriterClosure<[String: T]> {
    return { map, writer in
        try writer.writeMap(map, valueWriter: valueWriter, keyNodeInfo: keyNodeInfo, valueNodeInfo: valueNodeInfo, isFlattened: isFlattened)
    }
}

public func listWriter<T>(memberWriter: @escaping WriterClosure<T>, memberNodeInfo: NodeInfo, isFlattened: Bool) -> WriterClosure<[T]> {
    return { array, writer in
        try writer.writeList(array, memberWriter: memberWriter, memberNodeInfo: memberNodeInfo, isFlattened: isFlattened)
    }
}

public func timestampWriter(memberNodeInfo: NodeInfo, format: TimestampFormat) -> WriterClosure<Date> {
    return { date, writer in
        try writer.writeTimestamp(date, format: format)
    }
}

public extension String {

    static func write(_ value: String?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension RawRepresentable where RawValue == Int {

    static func write(_ value: Self?, to writer: Writer) throws {
        try writer.write(value?.rawValue)
    }
}

public extension RawRepresentable where RawValue == String {

    static func write(_ value: Self?, to writer: Writer) throws {
        try writer.write(value?.rawValue)
    }
}

public extension Bool {

    static func write(_ value: Bool?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Int {

    static func write(_ value: Int?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Date {

    static func write(_ value: Date?, to writer: Writer) throws {
        // TODO: write this correctly
        try writer.write(value?.timeIntervalSince1970)
    }
}

