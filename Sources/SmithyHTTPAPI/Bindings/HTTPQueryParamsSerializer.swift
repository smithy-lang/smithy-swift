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
@_spi(SchemaBasedSerde)
public final class HTTPQueryParamsSerializer: ShapeSerializer {
    public private(set) var queryItems = [URIQueryItem]()

    /// The query name to use while a single map entry is being serialized,
    /// or `nil` if a map entry is not currently being serialized.
    private var name: String?

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
        guard name != nil else { return }
        try value.forEach { try consumer($0, self) }
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        guard schema.hasTrait(HTTPQueryParamsTrait.self) else { return }
        defer { self.name = nil }
        for (key, entry) in value {
            self.name = key
            try consumer(entry, self)
        }
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        addToQueryString(value: "\(value)")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        addToQueryString(value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        addToQueryString(value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        addToQueryString(value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        addToQueryString(value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        addToQueryString(value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        addToQueryString(value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        addToQueryString(value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        addToQueryString(value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        addToQueryString(value: value)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        let timestampFormat = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        let timestamp = TimestampFormatter(format: timestampFormat).string(from: value)
        addToQueryString(value: timestamp)
    }

    public func writeNull(_ schema: Schema) throws {
        // Will only ever be called in the context of a null element of a sparse list value
        addToQueryString(value: "null")
    }

    public var data: Data { Data() } // not used for this serializer

    // MARK: - Private methods

    private func encoded<FP: FloatingPoint>(_ value: FP) -> String {
        guard !value.isNaN else { return "NaN" }
        switch value {
        case -FP.infinity: return "-Infinity"
        case FP.infinity: return "Infinity"
        default: return "\(value)"
        }
    }

    private func addToQueryString(value: String) {
        guard let name else { return }
        let queryItem = URIQueryItem(
            name: URLEncodingUtils.urlPercentEncodedForQuery(name),
            value: URLEncodingUtils.urlPercentEncodedForQuery(value)
        )
        queryItems.append(queryItem)
    }
}
