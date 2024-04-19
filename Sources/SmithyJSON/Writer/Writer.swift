//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyReadWrite.SmithyWriter
import enum SmithyReadWrite.Document
import enum SmithyTimestamps.TimestampFormat
import struct SmithyTimestamps.TimestampFormatter
import struct Foundation.Data
import struct Foundation.Date
import class Foundation.NSNumber

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
        let newChild = Writer(nodeInfo: nodeInfo, parent: self)
        children.append(newChild)
        return newChild
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

    func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
    }

    func write(_ value: Document?) throws {
        guard let value else { return }
        switch value {
        case .object(let object):
            try object.forEach { try self[.init($0.key)].write($0.value) }
            self.jsonNode = .object
        case .array(let array):
            try array.enumerated().forEach { try self[.init("\($0.offset)")].write($0.element) }
            self.jsonNode = .array
        case .boolean(let bool):
            try write(bool)
        case .number(let number):
            try write(number)
        case .string(let string):
            try write(string)
        case .null:
            self.jsonNode = .null
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
