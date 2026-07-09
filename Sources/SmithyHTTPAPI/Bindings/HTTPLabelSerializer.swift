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
import SmithySerialization

@_spi(SchemaBasedSerde)
public final class HTTPLabelSerializer: ShapeSerializer {
    private var transformed: String

    public init(uri: String) {
        self.transformed = uri
    }

    public func writeStruct<S>(_ schema: Smithy.Schema, _ value: S) throws where S : SerializableStruct {
        // no operation
    }

    public func writeList<E>(_ schema: Smithy.Schema, _ value: [E], _ consumer: (E, any ShapeSerializer) throws -> Void) throws {
        // no operation
    }

    public func writeMap<V>(_ schema: Smithy.Schema, _ value: [String : V], _ consumer: (V, any ShapeSerializer) throws -> Void) throws {
        // no operation
    }

    public func writeBoolean(_ schema: Smithy.Schema, _ value: Bool) throws {
        try writeString(schema, "\(value)")
    }

    public func writeByte(_ schema: Smithy.Schema, _ value: Int8) throws {
        try writeString(schema, "\(value)")
    }

    public func writeShort(_ schema: Smithy.Schema, _ value: Int16) throws {
        try writeString(schema, "\(value)")
    }

    public func writeInteger(_ schema: Smithy.Schema, _ value: Int) throws {
        try writeString(schema, "\(value)")
    }

    public func writeLong(_ schema: Smithy.Schema, _ value: Int) throws {
        try writeString(schema, "\(value)")
    }

    public func writeFloat(_ schema: Smithy.Schema, _ value: Float) throws {
        try writeString(schema, "\(value)")
    }

    public func writeDouble(_ schema: Smithy.Schema, _ value: Double) throws {
        try writeString(schema, "\(value)")
    }

    public func writeBigInteger(_ schema: Smithy.Schema, _ value: Int64) throws {
        try writeString(schema, "\(value)")
    }

    public func writeBigDecimal(_ schema: Smithy.Schema, _ value: Double) throws {
        try writeString(schema, "\(value)")
    }

    public func writeString(_ schema: Smithy.Schema, _ value: String) throws {
        guard schema.hasTrait(HTTPLabelTrait.self), let label = schema.id.member else { return }
        let nongreedyTemplate = "{\(label)}"
        let greedyTemplate = "{\(label)+}"
        if let nongreedyTemplateRange = transformed.range(of: nongreedyTemplate) {
            // URL-encode the value, also encoding '/' characters, and put in in the URI
            let pathComponent = URLEncodingUtils.urlPercentEncodedForQuery(value)
            transformed.replaceSubrange(nongreedyTemplateRange, with: pathComponent)
        } else if let greedyTemplateRange = transformed.range(of: greedyTemplate) {
            // URL-encode the value, preserving '/' characters, and put in in the URI
            let pathComponent = URLEncodingUtils.urlPercentEncodedForPath(value)
            transformed.replaceSubrange(greedyTemplateRange, with: pathComponent)
        }
    }

    public func writeBlob(_ schema: Smithy.Schema, _ value: Data) throws {
        // no operation
    }

    public func writeTimestamp(_ schema: Smithy.Schema, _ value: Date) throws {
        // TODO: implement me
        try writeString(schema, "\(value)")
    }

    public func writeNull(_ schema: Smithy.Schema) throws {
        // no operation
    }

    public var data: Data {
        Data()
    }

    public var uri: String { transformed }

    private var notImplemented: SerializerError { .init("Not implemented") }
}
