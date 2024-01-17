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

/// A class used to encode a tree of model data as XML.
///
/// Custom types (i.e. structures and unions) that are to be written as XML need to provide
/// a writing closure.  A writing closure is code generated for Smithy model types.
///
/// This writer will write all Swift types used by Smithy models, and will also write Swift
/// `Array` and `Dictionary` (optionally as flattened XML) given a writing closure for
/// their enclosed data types.
public class Writer {
    var content = ""
    var children: [Writer] = []
    weak var parent: Writer?
    let nodeInfo: NodeInfo
    public var nodeInfoPath: [NodeInfo] { (parent?.nodeInfoPath ?? []) + [nodeInfo] }

    // MARK: - init & deinit

    /// Used by the `DocumentWriter` to begin serialization of a model to XML.
    /// - Parameter rootNodeInfo: The node info for the root XML node.
    init(rootNodeInfo: NodeInfo) {
        self.nodeInfo = rootNodeInfo
    }

    private init(nodeInfo: NodeInfo, parent: Writer?) {
        self.nodeInfo = nodeInfo
        self.parent = parent
    }

    // MARK: - creating and detaching writers for subelements

    public subscript(_ nodeInfo: NodeInfo) -> Writer {
        let namespaceDef = nodeInfoPath.compactMap { $0.namespaceDef }.contains(nodeInfo.namespaceDef) ? nil : nodeInfo.namespaceDef
        let newNodeInfo = NodeInfo(nodeInfo.name, location: nodeInfo.location, namespaceDef: namespaceDef)
        let newChild = Writer(nodeInfo: newNodeInfo, parent: self)
        addChild(newChild)
        return newChild
    }

    /// Detaches this writer from its parent.  Typically used when this writer no longer
    /// belongs in the tree, either because its data is nil or its contents were flattened
    /// into its parents.
    public func detach() {
        parent?.children.removeAll { $0 === self }
        parent = nil
    }

    // MARK: - Writing values

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

    public func write(_ value: UInt8?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
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
            defer { detach() }
            guard let parent = self.parent else { return }
            for (key, value) in value {
                let entryWriter = parent[.init(nodeInfo.name)]
                try entryWriter[keyNodeInfo].write(key)
                try valueWritingClosure(value, entryWriter[valueNodeInfo])
            }
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
                namespaceDef: memberNodeInfo.namespaceDef
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

    public func write<T>(_ value: T, writingClosure: WritingClosure<T, Writer>) throws {
        try writingClosure(value, self)
    }

    // MARK: - Private methods

    private func addChild(_ child: Writer) {
        children.append(child)
        child.parent = self
    }

    private func record(string: String?) {
        guard let string else { detach(); return }
        content = string
    }
}
