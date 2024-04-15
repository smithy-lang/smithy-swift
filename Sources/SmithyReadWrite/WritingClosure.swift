//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum SmithyTimestamps.TimestampFormat

public typealias WritingClosure<T, Writer> = (T, Writer) throws -> Void

public func mapWritingClosure<T, Writer: SmithyWriter>(
    valueWritingClosure: @escaping WritingClosure<T, Writer>,
    keyNodeInfo: Writer.NodeInfo,
    valueNodeInfo: Writer.NodeInfo,
    isFlattened: Bool
) -> WritingClosure<[String: T]?, Writer> {
    return { map, writer in
        try writer.writeMap(
            map,
            valueWritingClosure: valueWritingClosure,
            keyNodeInfo: keyNodeInfo,
            valueNodeInfo: valueNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func listWritingClosure<T, Writer: SmithyWriter>(
    memberWritingClosure: @escaping WritingClosure<T, Writer>,
    memberNodeInfo: Writer.NodeInfo,
    isFlattened: Bool
) -> WritingClosure<[T]?, Writer> {
    return { array, writer in
        try writer.writeList(
            array,
            memberWritingClosure: memberWritingClosure,
            memberNodeInfo: memberNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func timestampWritingClosure<Writer: SmithyWriter>(format: TimestampFormat) -> WritingClosure<Date, Writer> {
    return { date, writer in
        try writer.writeTimestamp(date, format: format)
    }
}

public extension String {

    static func write<Writer: SmithyWriter>(value: String?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension RawRepresentable where RawValue == Int {

    static func write<Writer: SmithyWriter>(value: Self?, to writer: Writer) throws {
        try writer.write(value?.rawValue)
    }
}

public extension RawRepresentable where RawValue == String {

    static func write<Writer: SmithyWriter>(value: Self?, to writer: Writer) throws {
        try writer.write(value?.rawValue)
    }
}

public extension Bool {

    static func write<Writer: SmithyWriter>(value: Bool?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Int {

    static func write<Writer: SmithyWriter>(value: Int?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Int8 {

    static func write<Writer: SmithyWriter>(value: Int8?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Int16 {

    static func write<Writer: SmithyWriter>(value: Int16?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Double {

    static func write<Writer: SmithyWriter>(value: Double?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Float {

    static func write<Writer: SmithyWriter>(value: Float?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Data {

    static func write<Writer: SmithyWriter>(value: Data?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public extension Document {

    static func write<Writer: SmithyWriter>(value: Document?, to writer: Writer) throws {
        try writer.write(value)
    }
}

public func sparseFormOf<T, Writer: SmithyWriter>(
    writingClosure: @escaping WritingClosure<T?, Writer>
) -> WritingClosure<T?, Writer> {
    return { value, writer in
        if let value {
            try writingClosure(value, writer)
        } else {
            try writer.writeNull()
        }
    }
}
