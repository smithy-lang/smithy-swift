//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(SchemaBasedSerde)
import class Smithy.HTTPQueryTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import class Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import struct Smithy.URIQueryItem
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SmithyTimestamps)
import struct SmithyTimestamps.TimestampFormatter

/// Serializes members of a structure into HTTP query string items.
///
/// This serializer is a no-op for all types except string, boolean, timestamp, numbers,
/// and lists of those types.
@_spi(SchemaBasedSerde)
public final class HTTPQuerySerializer: ShapeSerializer {
    public private(set) var queryItems = [URIQueryItem]()

    /// The already-percent-encoded query name to use for the members of a list currently being
    /// serialized, or `nil` if a list is not being serialized.
    private var listName: String?

    public init() {}

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // no operation
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        guard let name = schema.getTrait(HTTPQueryTrait.self)?.name else { return }
        // Each list element is bound to a query item that repeats the list's query name.
        // The element schema does not carry the httpQuery trait, so the list's name is held
        // here for the scalar writers to use while the elements are being serialized.
        self.listName = URLEncodingUtils.urlPercentEncodedForQuery(name)
        defer { self.listName = nil }
        try value.forEach { try consumer($0, self) }
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        // no operation
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        guard let name = queryName(for: schema) else { return }
        addToQueryString(name: name, value: value)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        guard let name = queryName(for: schema) else { return }
        let timestampFormat = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        let timestamp = TimestampFormatter(format: timestampFormat).string(from: value)
        addToQueryString(name: name, value: timestamp)
    }

    public func writeNull(_ schema: Schema) throws {
        // Will only ever be called in the context of a null member of a sparse list
        guard let listName else { return }
        addToQueryString(name: listName, value: "null")
    }

    public var data: Data { Data() } // not used for this serializer

    // MARK: - Private methods

    /// Returns the already-percent-encoded query name for the value described by the passed schema,
    /// or `nil` if the value should not be bound to the query string.
    ///
    /// While a list is being serialized, the list's query name is returned for each element.
    /// Otherwise the name comes from the schema's `httpQuery` trait, and `nil` is returned if it
    /// has none.
    private func queryName(for schema: Schema) -> String? {
        if let listName { return listName }
        guard let name = schema.getTrait(HTTPQueryTrait.self)?.name else { return nil }
        return URLEncodingUtils.urlPercentEncodedForQuery(name)
    }

    /// Renders a floating-point value as a string, using the Smithy-defined tokens for
    /// the non-finite values NaN, Infinity, and -Infinity.
    private func encoded<FP: FloatingPoint>(_ value: FP) -> String {
        guard !value.isNaN else { return "NaN" }
        switch value {
        case -FP.infinity: return "-Infinity"
        case FP.infinity: return "Infinity"
        default: return "\(value)"
        }
    }

    /// Appends a query item, given an already-percent-encoded `name` and an un-encoded `value`.
    private func addToQueryString(name: String, value: String) {
        let queryItem = URIQueryItem(
            name: name,
            value: URLEncodingUtils.urlPercentEncodedForQuery(value)
        )
        queryItems.append(queryItem)
    }
}
