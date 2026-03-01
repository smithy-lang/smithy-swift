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

    private let interstitial = ", "
    private let redacted = "[REDACTED]"

    public init() {}

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        guard !isSensitive(schema) else { return }
        let storedIsFirstElement = isFirstElement
        isFirstElement = true
        string += "\(type(of: value))("
        let structMembers = schema.members
        for member in structMembers {
            try S.writeConsumer(member, value, self)
        }
        string += ")"
        isFirstElement = storedIsFirstElement
    }

    public func writeList<E>(_ schema: Schema, _ value: [E], _ consumer: WriteValueConsumer<E>) throws {
        guard !isSensitive(schema) else { return }
        string += "["
        let storedIsFirstElement = isFirstElement
        isFirstElement = true
        for element in value {
            try consumer(element, self)
        }
        string += "]"
        isFirstElement = storedIsFirstElement
    }

    public func writeMap<V>(_ schema: Schema, _ value: [String: V], _ consumer: WriteValueConsumer<V>) throws {
        guard !isSensitive(schema) else { return }
        guard !value.isEmpty else { string += "[:]"; return }
        string += "["
        let storedIsFirstElement = isFirstElement
        isFirstElement = true
        for (key, value) in value {
            try writeString(schema.key, key)
            string += ": "
            let storedIsFirstElement = isFirstElement
            isFirstElement = true
            try consumer(value, self)
            isFirstElement = storedIsFirstElement
        }
        string += "]"
        isFirstElement = storedIsFirstElement
    }

    public func writeBoolean(_ schema: Schema, _ value: Bool) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeByte(_ schema: Schema, _ value: Int8) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeShort(_ schema: Schema, _ value: Int16) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeInteger(_ schema: Schema, _ value: Int) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeLong(_ schema: Schema, _ value: Int) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeFloat(_ schema: Schema, _ value: Float) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeDouble(_ schema: Schema, _ value: Double) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeBigInteger(_ schema: Schema, _ value: Int64) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeBigDecimal(_ schema: Schema, _ value: Double) throws {
        guard !isSensitive(schema) else { return }
        string += "\(value)"
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        guard !isSensitive(schema) else { return }
        string += "\"\(value)\""
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        guard !isSensitive(schema) else { return }
        string += "<\(value.count) bytes>"
    }

    public func writeTimestamp(_ schema: Schema, _ value: Date) throws {
        guard !isSensitive(schema) else { return }
        string += ISO8601DateFormatter().string(from: value)
    }

    public func writeNull(_ schema: Schema) throws {
        guard !isSensitive(schema) else { return }
        string += "nil"
    }

    private func isSensitive(_ schema: Schema) -> Bool {
        if !isFirstElement { string += interstitial }
        isFirstElement = false
        if let memberName = schema.memberName {
            string += memberName + ": "
        }
        let isSensitive = schema.hasTrait(SensitiveTrait.self)
        if isSensitive {
            string += redacted
        }
        return isSensitive
    }

    public var data: Data {
        Data(string.utf8)
    }
}
