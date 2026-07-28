//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(SchemaBasedSerde)
import class Smithy.HTTPQueryParamsTrait
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

/// Serializes the single map member bound with the `httpQueryParams` trait into HTTP query string items.
///
/// The trait targets a `map` of `string`, or a `map` of `list` of `string`; each entry in the map is
/// serialized as though it had been individually bound with the `httpQuery` trait, using the map key as
/// the query parameter name. This serializer is a no-op for every member except that bound map.
///
/// Per the Smithy specification, when a query parameter name set here conflicts with one set by an
/// `httpQuery`-bound member, the `httpQuery` value takes precedence. That reconciliation is the
/// responsibility of the code that combines the query bindings, not of this serializer, which produces
/// a query item for every entry in the map.
@_spi(SchemaBasedSerde)
public final class HTTPQueryParamsSerializer: ShapeSerializer {
    public private(set) var queryItems = [URIQueryItem]()

    /// The already-percent-encoded query name to use while a single map entry is being serialized,
    /// or `nil` if a map entry is not currently being serialized.
    ///
    /// The `httpQueryParams` trait is applied to the map member, so the value schema carries no query
    /// name of its own. The current map key's encoded name is held here for the scalar and list writers
    /// to use while that entry's value is being serialized.
    private var currentKey: String?

    public init() {}

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // no operation
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        // Only reached for the list value of a `map` of `list` of `string`; each element repeats the
        // map key's query name. Outside a map entry there is no name to bind to, so it is a no-op.
        guard currentKey != nil else { return }
        try value.forEach { try consumer($0, self) }
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        guard schema.hasTrait(HTTPQueryParamsTrait.self) else { return }
        defer { self.currentKey = nil }
        for (key, entry) in value {
            self.currentKey = URLEncodingUtils.urlPercentEncodedForQuery(key)
            try consumer(entry, self)
        }
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: value)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        guard let name = currentKey else { return }
        let timestampFormat = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        let timestamp = TimestampFormatter(format: timestampFormat).string(from: value)
        addToQueryString(name: name, value: timestamp)
    }

    public func writeNull(_ schema: Schema) throws {
        // Will only ever be called in the context of a null element of a sparse list value
        guard let name = currentKey else { return }
        addToQueryString(name: name, value: "null")
    }

    public var data: Data { Data() } // not used for this serializer

    // MARK: - Private methods

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
