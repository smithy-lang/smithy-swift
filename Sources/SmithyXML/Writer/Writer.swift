//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import struct Foundation.Data
import typealias SmithyReadWrite.WritingClosure
import enum SmithyTimestamps.TimestampFormat
import struct SmithyTimestamps.TimestampFormatter

public class Writer {
    var content = ""
    var children: [Writer] = []
    weak var parent: Writer?
    let nodeInfo: NodeInfo
    public let nodeInfoPath: [NodeInfo]

    init(rootNodeInfo: NodeInfo) {
        self.nodeInfo = rootNodeInfo
        self.nodeInfoPath = [rootNodeInfo]
    }

    init(nodeInfo: NodeInfo, nodeInfoPath: [NodeInfo], parent: Writer?) {
        self.nodeInfo = nodeInfo
        self.nodeInfoPath = nodeInfoPath
        self.parent = parent
    }

    public subscript(_ nodeInfo: NodeInfo) -> Writer {
        let namespace = nodeInfoPath.compactMap { $0.namespace }.contains(nodeInfo.namespace) ? nil : nodeInfo.namespace
        let newNodeInfo = NodeInfo(nodeInfo.name, location: nodeInfo.location, namespace: namespace)
        let newChild = Writer(nodeInfo: newNodeInfo, nodeInfoPath: nodeInfoPath + [newNodeInfo], parent: self)
        addChild(newChild)
        return newChild
    }

    func addChild(_ child: Writer) {
        children.append(child)
        child.parent = self
    }

    public func detach() {
        parent?.children.removeAll { $0 === self }
        parent = nil
    }

    public func writeNil() throws {
        record(string: "null")
    }

    public func write(_ value: Bool?) throws {
        record(string: value.map { $0 ? "true" : "false" })
    }

    public func write(_ value: String?) throws {
        record(string: value)
    }

    public func write(_ value: Double?) throws {
        guard let value else { detach(); return }
        guard !value.isNaN else {
            record(string: "NaN")
            return
        }
        switch value {
        case .infinity:
            record(string: "Infinity")
        case -.infinity:
            record(string: "-Infinity")
        default:
            record(string: "\(value)")
        }
    }

    public func write(_ value: Float?) throws {
        guard let value else { detach(); return }
        guard !value.isNaN else {
            record(string: "NaN")
            return
        }
        switch value {
        case .infinity:
            record(string: "Infinity")
        case -.infinity:
            record(string: "-Infinity")
        default:
            record(string: "\(value)")
        }
    }

    public func write(_ value: Int?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Int8?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Int16?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Int32?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Int64?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: UInt?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: UInt8?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: UInt16?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: UInt32?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: UInt64?) throws {
        record(string: value.map { "\($0)" })
    }

    public func writeTimestamp(_ value: Date?, format: TimestampFormat) throws {
        guard let value else { detach(); return }
        record(string: TimestampFormatter(format: format).string(from: value))
    }

    public func write<T: RawRepresentable>(_ value: T?) throws where T.RawValue == Int {
        try write(value?.rawValue)
    }

    public func write<T: RawRepresentable>(_ value: T?) throws where T.RawValue == String {
        try write(value?.rawValue)
    }

    public func writeMap<T>(
        _ value: [String: T]?,
        valueWritingClosure: WritingClosure<T, Writer>,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { detach(); return }
        if isFlattened {
            guard let parent = self.parent else { return }
            for (key, value) in value {
                let entryWriter = parent[.init(nodeInfo.name)]
                try entryWriter[keyNodeInfo].write(key)
                try valueWritingClosure(value, entryWriter[valueNodeInfo])
            }
            detach()
        } else {
            for (key, value) in value {
                let entryWriter = self[.init("entry")]
                try entryWriter[keyNodeInfo].write(key)
                try valueWritingClosure(value, entryWriter[valueNodeInfo])
            }
        }
    }

    public func writeList<T>(
        _ value: [T]?,
        memberWritingClosure: WritingClosure<T, Writer>,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { detach(); return }
        if isFlattened {
            defer { detach() }
            guard let parent = self.parent, !nodeInfo.name.isEmpty else { return }
            let flattenedMemberNodeInfo = NodeInfo(
                nodeInfo.name,
                location: memberNodeInfo.location,
                namespace: memberNodeInfo.namespace
            )
            for member in value {
                try memberWritingClosure(member, parent[flattenedMemberNodeInfo])
            }
        } else {
            for member in value {
                try memberWritingClosure(member, self[memberNodeInfo])
            }
        }
    }

    public func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
    }

    private func record(string: String?) {
        guard let string else { detach(); return }
        content = string
    }
}
