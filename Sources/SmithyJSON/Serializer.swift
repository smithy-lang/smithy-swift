//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.JSONSerialization
import class Foundation.NSNumber
import struct Smithy.Document
@_spi(SchemaBasedSerde)
import struct Smithy.JSONNameTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.TimestampFormatTrait
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

@_spi(SchemaBasedSerde)
public final class Serializer: ShapeSerializer {
    var value: JSONValue?
    let usesJSONNameTrait: Bool

    public init(usesJSONNameTrait: Bool) {
        self.usesJSONNameTrait = usesJSONNameTrait
    }

    public func writeStruct<S>(_ schema: Schema, _ value: S) throws where S: SerializableStruct {
        try value.serializeMembers(schema, self)
//        for memberSchema in schema.members {
//            guard let key = try objectKey(for: memberSchema) else { continue }
//            let memberSerializer = Serializer(usesJSONNameTrait: usesJSONNameTrait)
//            object[key] = memberSerializer.value
//        }
        self.value = .object([:])  // FIXME: All structs & unions serialize as empty object
    }

    public func writeList<E>(
        _ schema: Schema,
        _ value: [E],
        _ consumer: (E, any ShapeSerializer) throws -> Void
    ) throws {
        var list = [JSONValue]()
        for element in value {
            let elementSerializer = Serializer(usesJSONNameTrait: usesJSONNameTrait)
            try consumer(element, elementSerializer)
            if let value = elementSerializer.value {
                list.append(value)
            }
        }
        self.value = .list(list)
    }

    public func writeMap<V>(
        _ schema: Schema,
        _ value: [String: V],
        _ consumer: (V, any ShapeSerializer) throws -> Void
    ) throws {
        var object = [String: JSONValue]()
        for (key, value) in value {
            let valueSerializer = Serializer(usesJSONNameTrait: usesJSONNameTrait)
            try consumer(value, valueSerializer)
            object[key] = valueSerializer.value
        }
        self.value = .object(object)
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        self.value = .bool(value)
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        self.value = .number(NSNumber(value: value))
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        self.value = .string(value)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        self.value = .string(value.base64EncodedString())
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        let timestampFormat: TimestampFormatTrait.Format
        if schema.type == .member {
            let memberTraits = schema.traits
            let memberTimestampFormat = memberTraits.getTrait(TimestampFormatTrait.self)?.format
            let targetTraits = schema.target!.traits
            let targetTimestampFormat = targetTraits.getTrait(TimestampFormatTrait.self)?.format
            timestampFormat = memberTimestampFormat ?? targetTimestampFormat ?? .epochSeconds
        } else {
            timestampFormat = schema.traits.getTrait(TimestampFormatTrait.self)?.format ?? .epochSeconds
        }
        switch timestampFormat {
        case .dateTime:
            let dateTimeString = TimestampFormatter(format: .dateTime).string(from: value)
            self.value = .string(dateTimeString)
        case .httpDate:
            let httpDateString = TimestampFormatter(format: .httpDate).string(from: value)
            self.value = .string(httpDateString)
        case .epochSeconds:
            let epochSecondsString = TimestampFormatter(format: .epochSeconds).string(from: value)
            guard let epochSeconds = Double(epochSecondsString) else {
                throw SerializerError("TimestampFormatter did not return valid seconds")
            }
            self.value = .number(NSNumber(value: epochSeconds))
        }
    }

    public func writeNull(_ schema: Schema) throws {
        self.value = .null
    }

    public var data: Data {
        get throws {
            guard let jsonObject = value?.jsonObject() else { return Data("{}".utf8) }
            return try JSONSerialization.data(withJSONObject: jsonObject)
        }
    }

    // MARK: - Private methods

    private func objectKey(for memberSchema: Schema) throws -> String? {
        return if usesJSONNameTrait, let jsonName = memberSchema.getTrait(JSONNameTrait.self)?.name {
            jsonName
        } else {
            memberSchema.id.member
        }
    }
}
