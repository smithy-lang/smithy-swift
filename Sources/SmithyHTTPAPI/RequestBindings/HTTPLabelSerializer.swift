//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(SchemaBasedSerde)
import class Smithy.HTTPLabelTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter
@_spi(SchemaBasedSerde)
import class Smithy.TimestampFormatTrait
import struct Smithy.URIQueryItem
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
import struct SmithySerialization.Operation
@_spi(SmithyTimestamps)
import struct SmithyTimestamps.TimestampFormatter

/// Serializes members of a structure into a URI template.
///
/// This serializer is a no-op for all types except string, boolean, timestamp, and numbers.
@_spi(SchemaBasedSerde)
public final class HTTPLabelSerializer: ShapeSerializer {
    var segments: [Substring.SubSequence]
    let uriQueryItems: [URIQueryItem]

    public init<Input, Output>(operation: Operation<Input, Output>) throws {
        let ext = try operation.schema.getOrCreateExtension(HTTPLabelOperationExtension.self)
        self.segments = ext.segments
        self.uriQueryItems = ext.uriQueryItems
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        // no operation
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        // no operation
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        // no operation
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        writeSegment(schema: schema, value: value ? "true" : "false")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        writeSegment(schema: schema, value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        writeSegment(schema: schema, value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        writeSegment(schema: schema, value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        writeSegment(schema: schema, value: value)
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

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        let timestampFormat = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        let timestamp = TimestampFormatter(format: timestampFormat).string(from: value)
        writeSegment(schema: schema, value: timestamp)
    }

    public func writeNull(_ schema: Schema) throws {
        // no operation
    }

    /// Returns a UTF-8 representation of the URI.
    public var data: Data? {
        Data(uri.utf8)
    }

    public var mediaType: String? { nil }

    public var uri: String { segments.joined(separator: "/") }

    private func writeSegment(schema: Schema, value: String) {
        guard let ext = schema.getExtension(HTTPLabelMemberExtension.self) else { return }
        if ext.isGreedy {
            self.segments[ext.segmentIndex] = URLEncodingUtils.urlPercentEncodedForPath(value)[...]
        } else {
            self.segments[ext.segmentIndex] = URLEncodingUtils.urlPercentEncodedForQuery(value)[...]
        }
    }
}

// MARK: - Schema extensions

/// Extracts the path and query string from an operation schema's URI.
///
/// The path is converted to segments and the members that are bound to segments are marked with their own schema extension.  This allows
/// maximum performance when serializing a path.
///
/// The query string is converted to `URIQueryItem`s and stored for future use.
private final class HTTPLabelOperationExtension: SchemaExtension {
    static let uniqueIndex: Int = schemaExtensionUniqueIndexCounter.getNextIndex()

    let segments: [Substring.SubSequence]
    let uriQueryItems: [URIQueryItem]

    init(schema: Schema) throws {

        // Extract the uri from the HTTP trait & break it down into segments separated by '/'
        guard let httpTrait = schema.getTrait(HTTPTrait.self) else {
            throw SerializerError("Schema does not have HTTPTrait")
        }
        let (path, literalQuery) = Self.split(uri: httpTrait.uri)
        self.segments = path.split(separator: "/", omittingEmptySubsequences: false)
        self.uriQueryItems = Self.queryItems(literalQuery: literalQuery)

        // For segments that bind to members, locate the member by extracting the member name from the segment
        // & put an extension on that member.
        // Segments that bind to members have format '{membername}' for non-greedy, '{membername+}' for greedy
        for (segmentIndex, var segment) in segments.enumerated() where segment.hasPrefix("{") {
            segment = segment.dropFirst(1)
            let isGreedy: Bool
            if segment.hasSuffix("+}") {
                isGreedy = true
                segment = segment.dropLast(2)
            } else { // presume segment ends in '}' if it didn't end with '+}'
                isGreedy = false
                segment = segment.dropLast(1)
            }
            let matchingMember = schema.input.members.first { memberSchema in
                guard let memberName = memberSchema.id.member else { return false }
                return memberName == segment
            }
            matchingMember?.setExtension(HTTPLabelMemberExtension(segmentIndex: segmentIndex, isGreedy: isGreedy))
        }
    }

    // MARK: Private methods

    /// Splits a URI into its path and its literal query string, if it has one.
    private static func split(uri: String) -> (path: String, literalQuery: Substring?) {
        guard let separator = uri.firstIndex(of: "?") else { return (uri, nil) }
        return (String(uri[uri.startIndex..<separator]), uri[uri.index(after: separator)...])
    }

    /// Parses the literal query string from a URI into query items.
    ///
    /// Names & values are used exactly as they appear in the model.  A name with no value, i.e. `?uploads`,
    /// becomes a query item with a `nil` value, which is rendered without a `=`.
    private static func queryItems(literalQuery: Substring?) -> [URIQueryItem] {
        guard let literalQuery else { return [] }
        return literalQuery.split(separator: "&").map { pair in
            guard let separator = pair.firstIndex(of: "=") else {
                return URIQueryItem(name: String(pair), value: nil)
            }
            let value = pair[pair.index(after: separator)...]
            return URIQueryItem(
                name: String(pair[pair.startIndex..<separator]),
                value: value.isEmpty ? nil : String(value)
            )
        }
    }
}

private final class HTTPLabelMemberExtension: SchemaExtension {
    static let uniqueIndex: Int = schemaExtensionUniqueIndexCounter.getNextIndex()

    let segmentIndex: Int
    let isGreedy: Bool

    init(schema: Schema) throws {
        throw SerializerError("init(schema:) not implemented")
    }

    init(segmentIndex: Int, isGreedy: Bool) {
        self.segmentIndex = segmentIndex
        self.isGreedy = isGreedy
    }
}
