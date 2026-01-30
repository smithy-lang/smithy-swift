//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.ISO8601DateFormatter
import struct Smithy.Schema
import struct Smithy.SensitiveTrait
import struct Smithy.ShapeID
import protocol Smithy.SmithyDocument

public class StringSerializer: ShapeSerializer {
    public private(set) var string = ""
    private var isFirstElement = true
    private var mapKey: String?

    private let interstitial = ", "
    private let redacted = "[REDACTED]"

    public init() {}

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(type(of: value))("
        let structMembers = schema.target?.members ?? schema.members
        let memberSerializer = StringSerializer()
        for member in structMembers {
            try S.writeConsumer(member, value, memberSerializer)
        }
        string += memberSerializer.string
        string += ")"
    }

    public func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "["
        let listSerializer = StringSerializer()
        for element in value {
            listSerializer.mapKey = ""
            try consumer(element, listSerializer)
        }
        string += listSerializer.string
        string += "]"
    }

    public func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "["
        if value.isEmpty { string += ":" }
        let mapSerializer = StringSerializer()
        for (key, value) in value {
            mapSerializer.mapKey = key
            try consumer(value, mapSerializer)
        }
        string += mapSerializer.string
        string += "]"
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "\"\(value)\""
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "<\(value.count) bytes>"
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += ISO8601DateFormatter().string(from: value)
    }

    public func writeNull(_ schema: Schema) throws {
        writeKey(schema)
        guard !isSensitive(schema) else { return }
        string += "nil"
    }

    private func writeKey(_ schema: Schema) {
        guard schema.type == .member else { return }
        if !isFirstElement { string += interstitial }
        isFirstElement = false
        guard mapKey != "" else { return }
        if let mapKey {
            string += "\"\(mapKey)\": "
            self.mapKey = nil
        } else {
            let key = mapKey ?? schema.id.member ?? "<no key>"
            string += "\(key): "
        }
    }

    private func isSensitive(_ schema: Schema) -> Bool {
        let isSensitive = schema.isSensitive
        if isSensitive {
            string += redacted
        }
        return isSensitive
    }

    public var data: Data {
        Data(string.utf8)
    }
}

private extension Schema {

    var isSensitive: Bool {
        if type == .member {
            target!.hasTrait(SensitiveTrait.self)
        } else {
            hasTrait(SensitiveTrait.self)
        }
    }
}
