//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyWriter
@_spi(SmithyDocumentImpl) import protocol Smithy.SmithyDocument
import enum Smithy.DocumentError
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter
import struct Foundation.Data
import struct Foundation.Date
import class Foundation.NSNumber

@_spi(SmithyReadWrite)
public final class Writer: SmithyWriter {
    public typealias NodeInfo = SmithyJSON.NodeInfo

    let nodeInfo: NodeInfo
    var jsonNode: JSONNode?
    var children: [Writer] = []
    weak var parent: Writer?

    public init(nodeInfo: NodeInfo) {
        self.nodeInfo = nodeInfo
    }

    public required init(nodeInfo: NodeInfo, parent: Writer? = nil) {
        self.nodeInfo = nodeInfo
        self.parent = parent
    }
}

public extension Writer {

    subscript(nodeInfo: NodeInfo) -> Writer {
        self.jsonNode = .object
        if let child = children.first(where: { $0.nodeInfo == nodeInfo }) {
            return child
        } else {
            let newChild = Writer(nodeInfo: nodeInfo, parent: self)
            children.append(newChild)
            return newChild
        }
    }

    func write(_ value: Bool?) throws {
        guard let value else { return }
        self.jsonNode = .bool(value)
    }

    func write(_ value: String?) throws {
        guard let value else { return }
        self.jsonNode = .string(value)
    }

    func write(_ value: Double?) throws {
        guard let value else { return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    func write(_ value: Float?) throws {
        guard let value else { return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    func write(_ value: Int?) throws {
        guard let value else { return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    func write(_ value: Int8?) throws {
        guard let value else { return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    func write(_ value: Int16?) throws {
        guard let value else { return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    func write(_ value: UInt8?) throws {
        guard let value else { return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    func write(_ value: Int64?) throws {
        guard let value else { return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
    }

    func write(_ value: SmithyDocument?) throws {
        guard let value else { return }
        switch value.type {
        case .map:
            let map = try value.asStringMap()
            try map.forEach { try self[.init($0.key)].write($0.value) }
            self.jsonNode = .object
        case .list:
            let list = try value.asList()
            try list.enumerated().forEach { try self[.init("\($0.offset)")].write($0.element) }
            self.jsonNode = .array
        case .boolean:
            let bool = try value.asBoolean()
            try write(bool)
        case .double:
            let double = try value.asDouble()
            try write(double)
        case .integer:
            let int = try value.asInteger()
            try write(int)
        case .float:
            let float = try value.asFloat()
            try write(float)
        case .long:
            let long = try value.asLong()
            try write(long)
        case .short:
            let short = try value.asShort()
            try write(short)
        case .byte:
            let byte = try value.asByte()
            try write(byte)
        case .bigInteger:
            let bigInteger = try value.asBigInteger()
            try write(bigInteger)
        case .bigDecimal:
            let bigDecimal = try value.asBigDecimal()
            try write(bigDecimal)
        case .string:
            let string = try value.asString()
            try write(string)
        case .blob:
            let data = try value.asBlob()
            try write(data)
        case .timestamp:
            let date = try value.asTimestamp()
            try writeTimestamp(date, format: .dateTime)
        case .structure:
            self.jsonNode = .null
        default:
            throw DocumentError.invalidJSONData
        }
    }

    func writeTimestamp(_ value: Date?, format: SmithyTimestamps.TimestampFormat) throws {
        guard let value else { return }
        switch format {
        case .epochSeconds:
            self.jsonNode = .number(NSNumber(value: value.timeIntervalSince1970))
        case .dateTime, .httpDate:
            self.jsonNode = .string(TimestampFormatter(format: format).string(from: value))
        }
    }

    func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == Int {
        try write(value?.rawValue)
    }

    func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == String {
        try write(value?.rawValue)
    }

    func writeMap<T>(
        _ value: [String: T]?,
        valueWritingClosure: (T, Writer) throws -> Void,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { return }
        self.jsonNode = .object
        for (key, value) in value {
            try valueWritingClosure(value, self[.init(key)])
        }
    }

    func writeList<T>(
        _ value: [T]?,
        memberWritingClosure: (T, Writer) throws -> Void,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { return }
        self.jsonNode = .array
        for member in value {
            let element = Writer(nodeInfo: "")
            addChild(element)
            try memberWritingClosure(member, element)
        }
    }

    func writeNull() throws {
        jsonNode = .null
    }

    // MARK: - Private methods

    private func addChild(_ child: Writer) {
        children.append(child)
        child.parent = self
    }
}
