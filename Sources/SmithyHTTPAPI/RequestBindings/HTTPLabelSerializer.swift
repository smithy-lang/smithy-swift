//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(SchemaBasedSerde)
import class Smithy.Schema
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

    /// The operation's resolved bindings, which hold the URI template and the segment each member
    /// is bound to.
    private let operationExtension: HTTPOperationExtension

    /// The URI's segments, with those already serialized replaced by their member's value.
    var segments: [Substring.SubSequence]

    var uriQueryItems: [URIQueryItem] { operationExtension.uriQueryItems }

    public init(operationExtension: HTTPOperationExtension) {
        self.operationExtension = operationExtension
        self.segments = operationExtension.segments
    }

    public convenience init<Input, Output>(operation: Operation<Input, Output>) throws {
        self.init(operationExtension: try operation.schema.getOrCreateExtension(HTTPOperationExtension.self))
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
        // A member not bound to a segment has no index in the table, and a schema that is not a member
        // of the input has an index of -1.
        let memberIndex = schema.index
        guard memberIndex >= 0, memberIndex < operationExtension.labelSegmentIndex.count,
              let segmentIndex = operationExtension.labelSegmentIndex[memberIndex]
        else { return }
        // A greedy label may span segments, so the slashes in its value are left unescaped.
        self.segments[segmentIndex] = operationExtension.labelIsGreedy[memberIndex]
            ? URLEncodingUtils.urlPercentEncodedForPath(value)[...]
            : URLEncodingUtils.urlPercentEncodedForQuery(value)[...]
    }
}
