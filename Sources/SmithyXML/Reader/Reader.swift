//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyReadWrite.SmithyReader
import enum SmithyReadWrite.Document
import typealias SmithyReadWrite.ReadingClosure
import struct Foundation.Date
import struct Foundation.Data
import enum SmithyTimestamps.TimestampFormat
import struct SmithyTimestamps.TimestampFormatter

public final class Reader: SmithyReader {
    public typealias ReaderNodeInfo = NodeInfo
    public internal(set) var content: String?
    public internal(set) var children: [Reader] = []
    public internal(set) weak var parent: Reader?
    public let nodeInfo: NodeInfo
    public var nodeInfoPath: [NodeInfo] { (parent?.nodeInfoPath ?? []) + [nodeInfo] }

    // MARK: - init & deinit

    /// Creates an "empty" reader.  This Reader will be returned when the data cannot be parsed.
    init() {
        self.nodeInfo = ""
    }

    /// Used to create a new XML node during reading from XML.
    /// - Parameter nodeInfo: The node info for this XML node.
    init(nodeInfo: NodeInfo) {
        self.nodeInfo = nodeInfo
    }

    private init(nodeInfo: NodeInfo, parent: Reader?) {
        self.nodeInfo = nodeInfo
        self.parent = parent
    }

    // MARK: - creating and detaching readers for subelements

    public subscript(_ nodeInfo: NodeInfo) -> Reader {
        if let match = children.first(where: {
            nodeInfo.prefix == $0.nodeInfo.prefix && nodeInfo.name == $0.nodeInfo.name
        }) {
            return match
        } else {
            // The queried node doesn't exist.  Return one that has nil content.
            return Reader(nodeInfo: nodeInfo, parent: self)
        }
    }

    func addChild(_ child: Reader) {
        children.append(child)
        child.parent = self
    }

    /// Detaches this reader from its parent.  Typically used when this reader no longer
    /// belongs in the tree, either because its data is nil or its contents were flattened
    /// into its parents.
    public func detach() {
        parent?.children.removeAll { $0 === self }
        parent = nil
    }

    public func unwrap() -> Reader {
        let parent = Reader()
        parent.addChild(self)
        return parent
    }

    // MARK: - Reading values

    public func readIfPresent<T>(readingClosure: ReadingClosure<T, Reader>) throws -> T? {
        // This guard stops infinite recursion when decoding recursive structs or unions.
        guard content != nil || !children.isEmpty else { return nil }
        return try readingClosure(self)
    }

    public func readIfPresent() throws -> String? {
        return content
    }

    public func readIfPresent() throws -> Int8? {
        guard let content else { return nil }
        return Int8(content)
    }

    public func readIfPresent() throws -> Int16? {
        guard let content else { return nil }
        return Int16(content)
    }

    public func readIfPresent() throws -> Int? {
        guard let content else { return nil }
        return Int(content)
    }

    public func readIfPresent() throws -> Float? {
        guard let content else { return nil }
        return Float(content)
    }

    public func readIfPresent() throws -> Double? {
        guard let content else { return nil }
        return Double(content)
    }

    public func readIfPresent() throws -> Bool? {
        guard let content else { return nil }
        return Bool(content)
    }

    public func readIfPresent() throws -> Data? {
        guard let content else { return nil }
        return Data(base64Encoded: Data(content.utf8))
    }

    public func readIfPresent() throws -> Document? {
        // No operation.  Smithy document not supported in XML
        return nil
    }

    public func readTimestampIfPresent(format: TimestampFormat) throws -> Date? {
        guard let content else { return nil }
        return TimestampFormatter(format: format).date(from: content)
    }

    public func readIfPresent<T: RawRepresentable>() throws -> T? where T.RawValue == Int {
        guard let rawValue: Int = try readIfPresent() else { return nil }
        return T(rawValue: rawValue)
    }

    public func readIfPresent<T: RawRepresentable>() throws -> T? where T.RawValue == String {
        guard let rawValue: String = try readIfPresent() else { return nil }
        return T(rawValue: rawValue)
    }

    public func readMapIfPresent<T>(
        valueReadingClosure: ReadingClosure<T?, Reader>,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws -> [String: T]? {
        var dict = [String: T]()
        if isFlattened {
            let entries = (parent?.children ?? []).filter { $0.nodeInfo.name == nodeInfo.name }
            guard !entries.isEmpty else { return nil }
            for entry in entries {
                guard let key = entry[keyNodeInfo].content,
                      let value = try valueReadingClosure(entry[valueNodeInfo]) else { continue }
                dict[key] = value
            }
        } else {
            if content == nil { return nil }
            let entries = children.filter { $0.nodeInfo.name == "entry" }
            for entry in entries {
                guard let key = entry[keyNodeInfo].content,
                      let value = try valueReadingClosure(entry[valueNodeInfo]) else { continue }
                dict[key] = value
            }
        }
        return dict
    }

    public func readListIfPresent<Member>(
        memberReadingClosure: ReadingClosure<Member, Reader>,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws -> [Member]? {
        var list = [Member]()
        if isFlattened {
            let members = (parent?.children ?? []).filter { $0.nodeInfo.name == nodeInfo.name }
            guard !members.isEmpty else { return nil }
            for member in members {
                guard let value = try memberReadingClosure(member) else { continue }
                list.append(value)
            }
        } else {
            if content == nil { return nil }
            let members = children.filter { $0.nodeInfo.name == memberNodeInfo.name }
            for member in members {
                guard let value = try memberReadingClosure(member) else { continue }
                list.append(value)
            }
        }
        return list
    }
}
