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
        matchNonGreedy(label: label, value: "\(value)")
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: "\(value)")
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: "\(value)")
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: "\(value)")
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: "\(value)")
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: encoded(value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: encoded(value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: "\(value)")
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }
        matchNonGreedy(label: label, value: encoded(value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        guard let label = checkForTraitAndGetLabel(schema: schema) else { return }

        if !matchNonGreedy(label: label, value: value) {
            matchGreedy(label: label, value: value)
        }
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

    @discardableResult
    private func matchNonGreedy(label: String, value: String) -> Bool {
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

    private func matchGreedy(label: String, value: String) {
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
        matchNonGreedy(label: label, value: "\(timestamp)")
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
