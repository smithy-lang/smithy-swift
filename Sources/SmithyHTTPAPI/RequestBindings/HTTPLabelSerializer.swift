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
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SmithyTimestamps)
import struct SmithyTimestamps.TimestampFormatter

/// Serializes members of a structure into a URI template.
///
/// This serializer is a no-op for all types except string, boolean, timestamp, and numbers.
@_spi(SchemaBasedSerde)
public final class HTTPLabelSerializer: ShapeSerializer {
    var segments: [Substring.SubSequence]

    public init(operation: any OperationProperties) throws {
        self.segments = try operation.schema.getOrCreateExtension(HTTPLabelOperationExtension.self).segments
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
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: value ? "true" : "false")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int32) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int64) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        writeSegment(schema: schema, value: value)
    }

    private func checkForTraitAndGetLabel(schema: Schema) -> String? {
        // Return nil unless this schema has the httpLabel trait & is a member
        guard schema.hasTrait(HTTPLabelTrait.self), let label = schema.id.member else { return nil }
        return label
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
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
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

final class HTTPLabelOperationExtension: SchemaExtension {
    static let uniqueIndex: Int = schemaExtensionUniqueIndexCounter.getNextIndex()

    let segments: [Substring.SubSequence]

    init(schema: Schema) throws {
        guard let httpTrait = schema.getTrait(HTTPTrait.self) else {
            throw SerializerError("Schema does not have HTTPTrait")
        }
        let uri = httpTrait.uri
        let index = uri.firstIndex(of: "?") ?? uri.endIndex
        let path = uri[..<index]
        self.segments = path.split(separator: "/", omittingEmptySubsequences: false)

        for (segmentIndex, var segment) in segments.enumerated() {
            if segment.hasPrefix("{") {
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
    }
}

final class HTTPLabelMemberExtension: SchemaExtension {
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
