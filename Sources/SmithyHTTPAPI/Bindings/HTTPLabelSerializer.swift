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
import class Smithy.Schema
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
    private var transformed: String

    public init(uri: String) {
        self.transformed = uri
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
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(schema: schema, value: "\(value)", label: label)
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        // Only continue if this schema is a member & it has the httpLabel trait
        guard schema.hasTrait(HTTPLabelTrait.self), let label = schema.id.member else { return }

        if !matchNonGreedy(schema: schema, value: value, label: label) {
            matchGreedy(schema: schema, value: value, label: label)
        }
    }

    private func checkForTraitAndGetLabel(schema: Schema) -> String? {
        // Return nil unless this schema has the httpLabel trait & is a member
        guard schema.hasTrait(HTTPLabelTrait.self), let label = schema.id.member else { return nil }
        return label
    }

    @discardableResult
    private func matchNonGreedy(schema: Schema, value: String, label: String) -> Bool {
        let nongreedyTemplate = "{\(label)}"
        // Try matching the nongreedy, then greedy template, and substitute
        if let nongreedyTemplateRange = transformed.range(of: nongreedyTemplate) {
            // URL-encode the value, also encoding '/' characters, and put in in the URI
            let pathComponent = URLEncodingUtils.urlPercentEncodedForQuery(value)
            transformed.replaceSubrange(nongreedyTemplateRange, with: pathComponent)
            return true
        } else {
            return false
        }
    }

    private func matchGreedy(schema: Schema, value: String, label: String) {
        let greedyTemplate = "{\(label)+}"
        if let greedyTemplateRange = transformed.range(of: greedyTemplate) {
            // URL-encode the value, preserving '/' characters, and put in in the URI
            let pathComponent = URLEncodingUtils.urlPercentEncodedForPath(value)
            transformed.replaceSubrange(greedyTemplateRange, with: pathComponent)
        }
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        let timestampFormat = schema.getTrait(TimestampFormatTrait.self)?.format ?? .dateTime
        let timestamp = TimestampFormatter(format: timestampFormat).string(from: value)
        matchNonGreedy(schema: schema, value: "\(timestamp)", label: label)
    }

    public func writeNull(_ schema: Schema) throws {
        // no operation
    }

    /// Returns a UTF-8 representation of the URI.
    public var data: Data {
        Data(transformed.utf8)
    }

    public var uri: String { transformed }
}
