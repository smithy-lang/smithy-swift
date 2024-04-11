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
    var jsonNode: JSONNode = .object
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

extension Writer {

    public subscript(nodeInfo: NodeInfo) -> Writer {
        self.jsonNode = .object
        let newChild = Writer(nodeInfo: nodeInfo, parent: self)
        children.append(newChild)
        return newChild
    }

    public func detach() {
        parent?.children.removeAll { $0 === self }
        parent = nil
    }

    public func write<T>(_ value: T, writingClosure: (T, Writer) throws -> Void) throws {
        try writingClosure(value, self)
    }

    public func write(_ value: Bool?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .bool(value)
    }

    public func write(_ value: String?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .string(value)
    }

    public func write(_ value: Double?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    public func write(_ value: Float?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    public func write(_ value: Int?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    public func write(_ value: Int8?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    public func write(_ value: Int16?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    public func write(_ value: UInt8?) throws {
        guard let value else { detach(); return }
        self.jsonNode = .number(NSNumber(value: value))
    }

    public func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
    }

    public func write(_ value: Document?) throws {
        guard let value else { detach(); return }
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

    public func writeTimestamp(_ value: Date?, format: SmithyTimestamps.TimestampFormat) throws {
        guard let value else { detach(); return }
        switch format {
        case .epochSeconds:
            self.jsonNode = .number(NSNumber(value: value.timeIntervalSince1970))
        case .dateTime, .httpDate:
            self.jsonNode = .string(TimestampFormatter(format: format).string(from: value))
        }
    }

    public func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == Int {
        try write(value?.rawValue)
    }

    public func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == String {
        try write(value?.rawValue)
    }

    public func writeMap<T>(
        _ value: [String: T]?,
        valueWritingClosure: (T, Writer) throws -> Void,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { detach(); return }
        self.jsonNode = .object
        for (key, value) in value {
            try valueWritingClosure(value, self[.init(key)])
        }
    }

    public func writeList<T>(
        _ value: [T]?,
        memberWritingClosure: (T, Writer) throws -> Void,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { detach(); return }
        self.jsonNode = .array
        for member in value {
            let element = Writer(nodeInfo: "")
            addChild(element)
            try memberWritingClosure(member, element)
        }
    }

    private func addChild(_ child: Writer) {
        children.append(child)
        child.parent = self
    }
}
