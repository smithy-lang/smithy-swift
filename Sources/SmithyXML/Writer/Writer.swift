//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(FoundationXML)
import class FoundationXML.XMLElement
import class FoundationXML.XMLNode
#else
import class Foundation.XMLElement
import class Foundation.XMLNode
#endif
import struct Foundation.Date
import struct Foundation.Data
import typealias SmithyReadWrite.WritingClosure
import enum SmithyTimestamps.TimestampFormat
import struct SmithyTimestamps.TimestampFormatter

public class Writer {
    let parent: Writer?
    let element: XMLElement
    public let nodeInfoPath: [NodeInfo]

    init(rootNodeInfo: NodeInfo) {
        self.parent = nil
        self.nodeInfoPath = [rootNodeInfo]
        self.element = XMLElement(name: rootNodeInfo.name, namespace: rootNodeInfo.namespace)
    }

    init(element: XMLElement, nodeInfoPath: [NodeInfo], parent: Writer?) {
        self.element = element
        self.nodeInfoPath = nodeInfoPath
        self.parent = parent
    }

    public subscript(_ nodeInfo: NodeInfo) -> Writer {
        let namespace = nodeInfoPath.compactMap({ $0.namespace }).contains(nodeInfo.namespace) ? nil : nodeInfo.namespace
        let newChild = XMLElement(name: nodeInfo.name, namespace: namespace)
        element.addChild(newChild)
        return Writer(element: newChild, nodeInfoPath: nodeInfoPath + [nodeInfo], parent: self)
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
                let entryWriter = parent[.init(element.name ?? "")]
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
            guard let parent = self.parent else { return }
            let flattenedMemberNodeInfo = NodeInfo(
                element.name ?? "",
                location: memberNodeInfo.location,
                namespace: memberNodeInfo.namespace
            )
            for member in value {
                try memberWritingClosure(member, parent[flattenedMemberNodeInfo])
            }
            detach()
        } else {
            for member in value {
                try memberWritingClosure(member, self[memberNodeInfo])
            }
        }
    }

    public func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
    }

    public func detach() {
        element.detach()
    }

    private func record(string: String?) {
        guard let string, let key = nodeInfoPath.last else { detach(); return }
        switch key.kind {
        case .attribute:
            (element.parent as? XMLElement)?.addAttribute(name: key.name, value: string)
            detach()
        case .element:
            element.stringValue = string
        default:
            fatalError("Unhandled type of XML node")
        }
    }
}

private extension NodeInfo {

    var kind: XMLNode.Kind {
        switch location {
        case .element: return .element
        case .attribute: return .attribute
        }
    }
}

private extension XMLElement {

    convenience init(name: String, namespace: NodeInfo.Namespace?) {
        self.init(name: name)
        guard let namespace else { return }
        let namespaceNode = XMLNode(kind: .namespace)
        namespaceNode.name = namespace.prefix
        namespaceNode.stringValue = namespace.uri
        addNamespace(namespaceNode)
    }

    func addAttribute(name: String, value: String) {
        let attribute = XMLNode(kind: .attribute)
        attribute.name = name
        attribute.stringValue = value
        addAttribute(attribute)
    }
}
