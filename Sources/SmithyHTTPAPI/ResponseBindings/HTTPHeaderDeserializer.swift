//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(SchemaBasedSerde)
import class Smithy.HTTPHeaderTrait
@_spi(SchemaBasedSerde)
import class Smithy.MediaTypeTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import class Smithy.SparseTrait
import enum Smithy.TimestampFormat
@_spi(SchemaBasedSerde)
import class Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import struct SmithySerialization.DecodedNull
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.ReadValueConsumer
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SmithyTimestamps)
import struct SmithyTimestamps.TimestampFormatter

/// Deserializes the HTTP headers of a response into the members of a structure.
///
/// Use this deserializer with the output or error structure of an HTTP operation.  Only the
/// members carrying the `httpHeader` trait are deserialized; all other members are left untouched
/// so that the deserializer for another binding may fill them.
///
/// A member whose header is absent from the response is left unset.
///
/// Only string, boolean, timestamp, numbers, and lists of those types may be bound to a header;
/// reading any other type throws an error.
///
/// A string carrying the `mediaType` trait is base64 encoded in a header, so it is decoded from
/// base64 as it is read.
@_spi(SchemaBasedSerde)
public final class HTTPHeaderDeserializer: ShapeDeserializer {

    /// The portion of the response headers that this deserializer reads.
    private enum Value {
        /// All headers in the response.  Only the deserializer created by the caller holds this.
        case headers(Headers)
        /// The values of the one header bound to the member being deserialized.
        case header([String])
        /// One element of a list-valued header.
        case element(String)
        /// A null element of a sparse list-valued header.
        case null
    }

    private let value: Value

    /// Creates a deserializer that reads structure members from the passed headers.
    /// - Parameter headers: The headers of the response being deserialized.
    public init(headers: Headers) {
        self.value = .headers(headers)
    }

    private init(_ value: Value) {
        self.value = value
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        guard case .headers(let headers) = self.value else {
            throw SerializerError("Cannot read structure \(schema.id) from a single HTTP header")
        }
        for memberSchema in schema.members {
            guard let name = memberSchema.getTrait(HTTPHeaderTrait.self)?.name else { continue }
            guard let headerValues = headers.values(for: name) else { continue }
            try value.deserializeMember(memberSchema, Self(.header(headerValues)))
        }
    }

    public func readList<E>(_ schema: Schema, _ consumer: ReadValueConsumer<E>) throws -> [E] {
        guard case .header(let headerValues) = value else {
            throw SerializerError("Expected an HTTP header value for list \(schema.id)")
        }
        // The elements of a list may be spread over repeated headers, delimited by commas within a
        // single header value, or both; so every header value is split and the results concatenated.
        let elementSchema = schema.member
        let elements = try headerValues.flatMap { try Self.split($0, elementSchema: elementSchema) }
        // A sparse list's null elements are serialized as the unquoted literal "null", and are read
        // back as null.  A quoted "null" is the string, not a null element.
        let isSparse = schema.hasTrait(SparseTrait.self)
        return try elements.map { element in
            let isNull = isSparse && !element.isQuoted && element.text == Self.nullLiteral
            return try consumer(Self(isNull ? .null : .element(element.text)))
        }
    }

    public func readMap<V>(_ schema: Schema, _ consumer: ReadValueConsumer<V>) throws -> [String: V] {
        throw SerializerError("Map \(schema.id) cannot be bound to an HTTP header")
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        let string = try string()
        guard let boolean = Bool(string) else { throw Self.notA("boolean", string, schema) }
        return boolean
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        throw SerializerError("Blob \(schema.id) cannot be bound to an HTTP header")
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        try integer(schema)
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        try integer(schema)
    }

    public func readInteger(_ schema: Schema) throws -> Int32 {
        try integer(schema)
    }

    public func readLong(_ schema: Schema) throws -> Int64 {
        try integer(schema)
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        try floatingPoint(schema)
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        try floatingPoint(schema)
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        try integer(schema)
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        try floatingPoint(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        let string = try string()
        // A string carrying the mediaType trait is always base64 encoded in a header.
        guard schema.hasTrait(MediaTypeTrait.self) else { return string }
        guard let data = Data(base64Encoded: string), let decoded = String(data: data, encoding: .utf8) else {
            throw Self.notA("base64-encoded string", string, schema)
        }
        return decoded
    }

    public func readDocument(_ schema: Schema) throws -> any SmithyDocument {
        throw SerializerError("Document \(schema.id) cannot be bound to an HTTP header")
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        let string = try string()
        let format = Self.timestampFormat(for: schema)
        guard let timestamp = TimestampFormatter(format: format).date(from: string) else {
            throw Self.notA("\(format) timestamp", string, schema)
        }
        return timestamp
    }

    /// The number of headers in the response, when this deserializer holds them all.
    ///
    /// Returns `-1` once a header has been selected for a member, since the number of elements in
    /// that header is not known until it is split.
    public var containerSize: Int {
        guard case .headers(let headers) = value else { return -1 }
        return headers.headers.count
    }

    // MARK: - Private methods

    /// The string to be read as a value by this deserializer.
    private func string() throws -> String {
        switch value {
        case .headers:
            throw SerializerError("Cannot read a value from all of the response headers")
        case .header(let headerValues):
            // A header that appears more than once reads as its comma-delimited equivalent.
            return headerValues.joined(separator: ",")
        case .element(let element):
            return element
        case .null:
            throw DecodedNull()
        }
    }

    private func integer<I: FixedWidthInteger>(_ schema: Schema) throws -> I {
        let string = try string()
        guard let integer = I(string) else { throw Self.notA("\(I.self)", string, schema) }
        return integer
    }

    private func floatingPoint<F: BinaryFloatingPoint & LosslessStringConvertible>(
        _ schema: Schema
    ) throws -> F {
        let string = try string()
        switch string {
        case "NaN": return F.nan
        case "Infinity": return F.infinity
        case "-Infinity": return -F.infinity
        default:
            guard let floatingPoint = F(string) else { throw Self.notA("\(F.self)", string, schema) }
            return floatingPoint
        }
    }

    private static func notA(_ type: String, _ value: String, _ schema: Schema) -> SerializerError {
        SerializerError("Header value \"\(value)\" for \(schema.id) is not a \(type)")
    }

    private static func timestampFormat(for schema: Schema) -> TimestampFormat {
        // Headers default to the http-date (IMF-fixdate) format, unlike most other bindings.
        schema.getTrait(TimestampFormatTrait.self)?.format ?? .httpDate
    }

    // MARK: - Private methods for splitting a header value into list elements

    private static let nullLiteral = "null"
    private static let quote: Character = "\""
    private static let delimiter: Character = ","

    /// One element of a list, as read from a header value.
    private struct Element {
        /// The element's text, with any quoting and escaping removed.
        let text: String
        /// Whether the element was quoted in the header value.
        ///
        /// Quoting is what distinguishes the string `"null"` from a sparse list's null element.
        let isQuoted: Bool
    }

    /// Splits one header value into the elements of a list that it contains.
    private static func split(_ headerValue: String, elementSchema: Schema) throws -> [Element] {
        if elementSchema.type == .timestamp, timestampFormat(for: elementSchema) == .httpDate {
            return try splitHTTPDates(headerValue).map { Element(text: $0, isQuoted: false) }
        }
        return try splitElements(headerValue)
    }

    /// Splits one header value on its commas, honoring quoted elements.
    private static func splitElements(_ headerValue: String) throws -> [Element] {
        var elements = [Element]()
        var index = headerValue.startIndex
        while index < headerValue.endIndex {
            switch headerValue[index] {
            case " ", "\t":
                // Whitespace before an element is not part of it.
                index = headerValue.index(after: index)
            case quote:
                elements.append(Element(text: try readQuoted(headerValue, from: &index), isQuoted: true))
            default:
                elements.append(Element(text: readUnquoted(headerValue, from: &index), isQuoted: false))
            }
        }
        return elements
    }

    /// Reads the quoted element starting at `index`, then advances `index` past the element and its delimiter.
    private static func readQuoted(_ headerValue: String, from index: inout String.Index) throws -> String {
        var cursor = headerValue.index(after: index) // Skip the opening quote.
        var element = ""
        var isQuoteClosed = false
        while cursor < headerValue.endIndex, !isQuoteClosed {
            let character = headerValue[cursor]
            cursor = headerValue.index(after: cursor)
            switch character {
            case "\\":
                // A backslash escapes the character that follows it.
                guard cursor < headerValue.endIndex else { break }
                element.append(headerValue[cursor])
                cursor = headerValue.index(after: cursor)
            case quote:
                isQuoteClosed = true
            default:
                element.append(character)
            }
        }
        guard isQuoteClosed else {
            throw SerializerError("HTTP header list value \"\(headerValue)\" has an unclosed quoted element")
        }
        // Consume the whitespace and delimiter that follow this element, if any.
        while cursor < headerValue.endIndex {
            let character = headerValue[cursor]
            cursor = headerValue.index(after: cursor)
            if character == delimiter { break }
            guard character == " " || character == "\t" else {
                throw SerializerError(
                    "HTTP header list value \"\(headerValue)\" has unexpected text after a quoted element"
                )
            }
        }
        index = cursor
        return element
    }

    /// Reads the unquoted element starting at `index`, then advances `index` past the element and its delimiter.
    private static func readUnquoted(_ headerValue: String, from index: inout String.Index) -> String {
        var cursor = index
        while cursor < headerValue.endIndex, headerValue[cursor] != delimiter {
            cursor = headerValue.index(after: cursor)
        }
        let element = headerValue[index..<cursor]
        // Consume the delimiter that ends this element, if any.
        index = cursor < headerValue.endIndex ? headerValue.index(after: cursor) : cursor
        return element.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Splits one header value into the http-date timestamps that it contains.
    ///
    /// The http-date (IMF-fixdate) format contains a comma of its own, so a list of http-date
    /// timestamps is delimited by every second comma in the header value.
    private static func splitHTTPDates(_ headerValue: String) throws -> [String] {
        guard !headerValue.isEmpty else { return [] }
        let commaCount = headerValue.filter { $0 == delimiter }.count
        // A single timestamp holds one comma; each timestamp after the first adds two.
        guard commaCount > 1 else { return [headerValue.trimmingCharacters(in: .whitespacesAndNewlines)] }
        guard !commaCount.isMultiple(of: 2) else {
            throw SerializerError("HTTP header list value \"\(headerValue)\" is not a list of http-date timestamps")
        }
        var timestamps = [String]()
        var start = headerValue.startIndex
        var index = headerValue.startIndex
        var commasSinceStart = 0
        while index < headerValue.endIndex {
            if headerValue[index] == delimiter {
                commasSinceStart += 1
                if commasSinceStart == 2 {
                    timestamps.append(headerValue[start..<index].trimmingCharacters(in: .whitespacesAndNewlines))
                    start = headerValue.index(after: index)
                    commasSinceStart = 0
                }
            }
            index = headerValue.index(after: index)
        }
        timestamps.append(headerValue[start...].trimmingCharacters(in: .whitespacesAndNewlines))
        return timestamps
    }
}
