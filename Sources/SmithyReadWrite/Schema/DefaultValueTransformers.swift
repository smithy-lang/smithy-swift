//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import protocol Smithy.SmithyDocument
import struct Smithy.Document

@_spi(SchemaBasedSerde)
public enum DefaultValueTransformer {

//    public static func optional<Base: DeserializableShape>(_ document: (any SmithyDocument)?) throws -> Base? {
//        return document != nil ? Base() : nil
//    }
//
//    public static func required<Base: DeserializableShape>(_ document: (any SmithyDocument)?) throws -> Base {
//        guard let value: Base = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional<Element>(_ document: (any SmithyDocument)?) throws -> [Element]? {
//        return document != nil ? [] : nil
//    }
//
//    public static func required<Element>(_ document: (any SmithyDocument)?) throws -> [Element] {
//        guard let value: [Element] = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional<Element>(_ document: (any SmithyDocument)?) throws -> [String: Element]? {
//        return document != nil ? [:] : nil
//    }
//
//    public static func required<Element>(_ document: (any SmithyDocument)?) throws -> [String: Element] {
//        guard let value: [String: Element] = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional<Enum: RawRepresentable>(_ document: (any SmithyDocument)?) throws -> Enum? where Enum.RawValue == String {
//        guard let rawValue = try document?.asString() else { return nil }
//        return Enum(rawValue: rawValue)
//    }
//
//    public static func required<Enum: RawRepresentable>(_ document: (any SmithyDocument)?) throws -> Enum where Enum.RawValue == String {
//        guard let value: Enum = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional<IntEnum: RawRepresentable>(_ document: (any SmithyDocument)?) throws -> IntEnum? where IntEnum.RawValue == Int {
//        guard let rawValue = try document?.asInteger() else { return nil }
//        return IntEnum(rawValue: rawValue)
//    }
//
//    public static func required<IntEnum: RawRepresentable>(_ document: (any SmithyDocument)?) throws -> IntEnum where IntEnum.RawValue == Int {
//        guard let value: IntEnum = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Bool? {
//        return try document?.asBoolean()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Bool {
//        guard let value: Bool = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Data? {
//        return try document?.asBlob()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Data {
//        guard let value: Data = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Date? {
//        return try document?.asTimestamp()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Date {
//        guard let value: Date = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> String? {
//        return try document?.asString()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> String {
//        guard let value: String = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Int8? {
//        return try document?.asByte()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Int8 {
//        guard let value: Int8 = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Int16? {
//        return try document?.asShort()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Int16 {
//        guard let value: Int16 = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Int? {
//        return try document?.asInteger()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Int {
//        guard let value: Int = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Float? {
//        return try document?.asFloat()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Float {
//        guard let value: Float = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Double? {
//        return try document?.asDouble()
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Double {
//        guard let value: Double = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
//
//    public static func optional(_ document: (any SmithyDocument)?) throws -> Document? {
//        return try document.map { Document($0) }
//    }
//
//    public static func required(_ document: (any SmithyDocument)?) throws -> Document {
//        guard let value: Document = try optional(document) else { throw ReaderError.requiredValueNotPresent }
//        return value
//    }
}
