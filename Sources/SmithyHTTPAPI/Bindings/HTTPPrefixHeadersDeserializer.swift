//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.HTTPPrefixHeadersTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.ReadValueConsumer
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer

/// Deserializes HTTP headers into the single map member bound with the `httpPrefixHeaders` trait.
///
/// Every header whose name starts with the trait's prefix becomes one entry in the map, with the
/// prefix removed from the header name to form the entry's key.  An empty prefix matches every
/// header, so all of them are collected into the map.  Prefixes are matched case-insensitively,
/// since HTTP header names are case-insensitive.
///
/// A header that is also bound to a member with the `httpHeader` trait is still collected into the
/// map; unlike serialization, deserialization gives the `httpHeader` binding no precedence.
///
/// The `httpPrefixHeaders` trait may only be applied to a non-sparse map of string to string, so
/// reading any other type from this deserializer throws.
@_spi(SchemaBasedSerde)
public final class HTTPPrefixHeadersDeserializer: ShapeDeserializer {
    private let headers: Headers

    /// The value of the header currently being read, or `nil` if a header is not being read.
    private var value: String?

    public init(headers: Headers) {
        self.headers = headers
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        // The trait is structurally exclusive, so a structure has at most one member bound with it.
        // That member is the only one this deserializer fills; all others are left untouched.
        guard let member = schema.members.first(where: { $0.hasTrait(HTTPPrefixHeadersTrait.self) })
        else { return }
        try value.deserializeMember(member, self)
    }

    public func readMap<V>(_ schema: Schema, _ consumer: ReadValueConsumer<V>) throws -> [String: V] {
        guard let prefix = schema.getTrait(HTTPPrefixHeadersTrait.self)?.prefix else { return [:] }
        let lowercasedPrefix = prefix.lowercased()
        defer { self.value = nil }
        var map = [String: V]()
        for header in headers.headers where header.name.lowercased().hasPrefix(lowercasedPrefix) {
            // The key is the remainder of the header name after the prefix, in the case it was
            // received; the case of a header name is not guaranteed to be preserved in transit.
            let key = String(header.name.dropFirst(prefix.count))
            // A header that was received more than once is combined into one comma-delimited value.
            self.value = header.value.joined(separator: ",")
            map.updateValue(try consumer(self), forKey: key)
        }
        return map
    }

    public func readString(_ schema: Schema) throws -> String {
        // Outside of a map entry there is no header value to read from.
        guard let value else { throw notBound("A string") }
        return value
    }

    public func readList<E>(_ schema: Schema, _ consumer: ReadValueConsumer<E>) throws -> [E] {
        throw notBound("A list")
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        throw notBound("A boolean")
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        throw notBound("A blob")
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        throw notBound("A byte")
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        throw notBound("A short")
    }

    public func readInteger(_ schema: Schema) throws -> Int32 {
        throw notBound("An integer")
    }

    public func readLong(_ schema: Schema) throws -> Int64 {
        throw notBound("A long")
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        throw notBound("A float")
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        throw notBound("A double")
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        throw notBound("A big integer")
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        throw notBound("A big decimal")
    }

    public func readDocument(_ schema: Schema) throws -> any SmithyDocument {
        throw notBound("A document")
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        throw notBound("A timestamp")
    }

    public var containerSize: Int { -1 } // not used for this deserializer

    // MARK: - Private methods

    private func notBound(_ subject: String) -> SerializerError {
        SerializerError("\(subject) cannot be bound to a prefixed HTTP header")
    }
}
