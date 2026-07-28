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
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import class Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SmithyTimestamps)
import struct SmithyTimestamps.TimestampFormatter

/// Serializes members of a structure into HTTP headers.
///
/// This serializer is a no-op for all types except string, boolean, timestamp, numbers,
/// and lists of those types.
@_spi(SchemaBasedSerde)
public final class HTTPHeaderSerializer: ShapeSerializer {
    public private(set) var headers = Headers()

    /// The header name to use for the members of a list currently being serialized, or `nil`
    /// if a list is not being serialized.
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
        guard let name = schema.getTrait(HTTPHeaderTrait.self)?.name else { return }
        // An empty list still serializes to a header, present with an empty value.
        guard !value.isEmpty else {
            headers.add(name: name, value: "")
            return
        }
        // Each list element is appended to the header that shares the list's header name.
        // The element schema does not carry the httpHeader trait, so the list's name is held
        // here for the scalar writers to use while the elements are being serialized.
        self.listName = name
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
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: "\(value)")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        guard let name = headerName(for: schema) else { return }
        addToHeaders(name: name, value: value)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        guard let name = headerName(for: schema) else { return }
        // Headers default to the http-date (IMF-fixdate) format, unlike most other bindings.
        let timestampFormat = schema.getTrait(TimestampFormatTrait.self)?.format ?? .httpDate
        let timestamp = TimestampFormatter(format: timestampFormat).string(from: value)
        // Timestamps are never quoted, even as list elements, so they are added directly.
        headers.add(name: name, value: timestamp)
    }

    public func writeNull(_ schema: Schema) throws {
        // Will only ever be called in the context of a null member of a sparse list
        guard let listName else { return }
        headers.add(name: listName, value: "null")
    }

    public var data: Data { Data() } // not used for this serializer

    // MARK: - Private methods

    /// Returns the header name for the value described by the passed schema, or `nil` if the value
    /// should not be bound to a header.
    ///
    /// While a list is being serialized, the list's header name is returned for each element.
    /// Otherwise the name comes from the schema's `httpHeader` trait, and `nil` is returned if it
    /// has none.
    private func headerName(for schema: Schema) -> String? {
        if let listName { return listName }
        return schema.getTrait(HTTPHeaderTrait.self)?.name
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

    /// Appends a header value under the given name.
    ///
    /// A list element is quoted, when needed, so that any comma it contains is not mistaken for a
    /// list delimiter when the header is later parsed.  A scalar value is added verbatim.
    private func addToHeaders(name: String, value: String) {
        headers.add(name: name, value: listName != nil ? Self.quoteHeaderValue(value) : value)
    }

    /// The characters in an HTTP header list value that require the value to be quoted.
    private static let quotableHeaderValueChars = "\",()"

    /// Quotes and escapes a header list value if it contains whitespace at either end or any
    /// character that would otherwise be ambiguous when the compact list representation is parsed.
    private static func quoteHeaderValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let needsQuoting = trimmed.count != value.count || value.contains { char in
            quotableHeaderValueChars.contains(char)
        }
        guard needsQuoting else { return value }
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
