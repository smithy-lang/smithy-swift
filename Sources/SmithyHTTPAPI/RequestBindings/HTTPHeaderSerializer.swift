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

    /// The headers serialized so far, in the order that their members were serialized.
    ///
    /// The `httpHeader` bindings of a structure are case-insensitively unique, which the model has
    /// already been validated for, so a member's header is appended without first searching for an
    /// existing header of the same name.  Searching would make serializing a structure with `n`
    /// header bindings cost `O(n²)` name comparisons.
    private var serialized = [Header]()

    /// The header name to use for the members of a list currently being serialized, or `nil`
    /// if a list is not being serialized.
    private var listName: String?

    /// The position in `serialized` of the header that holds the list currently being serialized,
    /// or `nil` if no element of that list has been serialized yet.
    ///
    /// Every element of a list is bound to the same single header, so the first element appends that
    /// header and the rest append their values to it.
    private var listHeaderIndex: Int?

    public var headers: Headers {
        var headers = Headers()
        headers.headers = serialized
        return headers
    }

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
            serialized.append(Header(name: name, value: ""))
            return
        }
        // Each list element is appended to the header that shares the list's header name.
        // The element schema does not carry the httpHeader trait, so the list's name is held
        // here for the scalar writers to use while the elements are being serialized.
        // A header binding may not nest lists, so a single list needs tracking at a time.
        self.listName = name
        self.listHeaderIndex = nil
        defer {
            self.listName = nil
            self.listHeaderIndex = nil
        }
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
        addToHeaders(schema: schema, value: "\(value)")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        addToHeaders(schema: schema, value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        addToHeaders(schema: schema, value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        addToHeaders(schema: schema, value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        addToHeaders(schema: schema, value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        addToHeaders(schema: schema, value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        addToHeaders(schema: schema, value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        addToHeaders(schema: schema, value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        addToHeaders(schema: schema, value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        addToHeaders(schema: schema, value: value)
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
        append(name: name, value: timestamp)
    }

    public func writeNull(_ schema: Schema) throws {
        // Will only ever be called in the context of a null member of a sparse list
        guard let listName else { return }
        append(name: listName, value: "null")
    }

    public var data: Data? { nil } // not used for this serializer

    public var mediaType: String? { nil }

    // MARK: - Private methods

    private func headerName(for schema: Schema) -> String? {
        if let listName { return listName }
        return schema.getTrait(HTTPHeaderTrait.self)?.name
    }

    private func encoded<FP: FloatingPoint>(_ value: FP) -> String {
        guard !value.isNaN else { return "NaN" }
        switch value {
        case -FP.infinity: return "-Infinity"
        case FP.infinity: return "Infinity"
        default: return "\(value)"
        }
    }

    private func addToHeaders(schema: Schema, value: String) {
        guard let name = headerName(for: schema) else { return }
        if schema.hasTrait(MediaTypeTrait.self) {
            // Any string with a media type trait gets Base64-encoded
            append(name: name, value: Data(value.utf8).base64EncodedString())
        } else {
            append(name: name, value: listName != nil ? Self.quoteHeaderValue(value) : value)
        }
    }

    /// Adds a value to the header named `name`.
    ///
    /// While a list is being serialized every value joins the one header bound to that list.  Outside
    /// of a list the name belongs to a single member, so its header is appended directly.
    private func append(name: String, value: String) {
        if let listHeaderIndex {
            serialized[listHeaderIndex].value.append(value)
            return
        }
        if listName != nil {
            listHeaderIndex = serialized.count
        }
        serialized.append(Header(name: name, value: value))
    }

    private static let quotableHeaderValueChars = "\",()"

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
