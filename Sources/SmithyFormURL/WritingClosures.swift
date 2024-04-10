////
//// Copyright Amazon.com Inc. or its affiliates.
//// All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import struct Foundation.Date
//import typealias SmithyReadWrite.WritingClosure
//import enum SmithyTimestamps.TimestampFormat
//
//public func mapWritingClosure<T>(
//    valueWritingClosure: @escaping WritingClosure<T, Writer>,
//    keyNodeInfo: NodeInfo,
//    valueNodeInfo: NodeInfo,
//    isFlattened: Bool
//) -> WritingClosure<[String: T], Writer> {
//    return { map, writer in
//        try writer.writeMap(
//            map,
//            valueWritingClosure: valueWritingClosure,
//            keyNodeInfo: keyNodeInfo,
//            valueNodeInfo: valueNodeInfo,
//            isFlattened: isFlattened
//        )
//    }
//}
//
//public func listWritingClosure<T>(
//    memberWritingClosure: @escaping WritingClosure<T, Writer>,
//    memberNodeInfo: NodeInfo,
//    isFlattened: Bool
//) -> WritingClosure<[T], Writer> {
//    return { array, writer in
//        try writer.writeList(
//            array,
//            memberWritingClosure: memberWritingClosure,
//            memberNodeInfo: memberNodeInfo,
//            isFlattened: isFlattened
//        )
//    }
//}
//
//public func timestampWritingClosure(format: TimestampFormat) -> WritingClosure<Date, Writer> {
//    return { date, writer in
//        try writer.writeTimestamp(date, format: format)
//    }
//}
//
//public extension String {
//
//    static func writingClosure(_ value: String?, to writer: Writer) throws {
//        try writer.write(value)
//    }
//}
//
//public extension RawRepresentable where RawValue == Int {
//
//    static func writingClosure(_ value: Self?, to writer: Writer) throws {
//        try writer.write(value?.rawValue)
//    }
//}
//
//public extension RawRepresentable where RawValue == String {
//
//    static func writingClosure(_ value: Self?, to writer: Writer) throws {
//        try writer.write(value?.rawValue)
//    }
//}
//
//public extension Bool {
//
//    static func writingClosure(_ value: Bool?, to writer: Writer) throws {
//        try writer.write(value)
//    }
//}
//
//public extension Int {
//
//    static func writingClosure(_ value: Int?, to writer: Writer) throws {
//        try writer.write(value)
//    }
//}
