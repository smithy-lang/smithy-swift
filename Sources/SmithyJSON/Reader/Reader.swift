//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyReadWrite.SmithyReader
import enum SmithyReadWrite.Document
import typealias SmithyReadWrite.ReadingClosure
import enum SmithyReadWrite.ReaderError
import enum SmithyTimestamps.TimestampFormat
import struct SmithyTimestamps.TimestampFormatter
import struct Foundation.Data
import struct Foundation.Date
import class Foundation.NSNull
import class Foundation.NSNumber
import func CoreFoundation.CFGetTypeID
import func CoreFoundation.CFBooleanGetTypeID

public final class Reader: SmithyReader {
    public typealias NodeInfo = SmithyJSON.NodeInfo

    public let nodeInfo: NodeInfo
    let jsonNode: JSONNode?
    public internal(set) var children = [Reader]()
    public internal(set) weak var parent: Reader?
    public var hasContent: Bool { jsonNode != nil && jsonNode != .null }

    init(nodeInfo: NodeInfo, jsonObject: Any, parent: Reader? = nil) throws {
        self.nodeInfo = nodeInfo
        self.jsonNode = try Self.jsonNode(for: jsonObject)
        self.parent = parent
        self.children = try Self.children(from: jsonObject, parent: self)
    }

    init(nodeInfo: NodeInfo, parent: Reader?) {
        self.nodeInfo = nodeInfo
        self.jsonNode = nil
        self.parent = parent
    }

    private static func jsonNode(for jsonObject: Any) throws -> JSONNode {
        if jsonObject is [String: Any] {
            return .object
        } else if jsonObject is [Any] {
            return .array
        } else if let nsNumber = jsonObject as? NSNumber, CFGetTypeID(nsNumber) == CFBooleanGetTypeID() {
            return .bool(nsNumber.boolValue)
        } else if let nsNumber = jsonObject as? NSNumber {
            return .number(nsNumber)
        } else if let string = jsonObject as? String {
            return .string(string)
        } else if jsonObject is NSNull {
            return .null
        } else {
            throw JSONError.unknownJSONContent
        }
    }

    private static func children(from jsonObject: Any?, parent: Reader) throws -> [Reader] {
        if let object = jsonObject as? [String: Any] {
            return try object.map { try Reader(nodeInfo: .init($0.key), jsonObject: $0.value, parent: parent) }
        } else if let list = jsonObject as? [Any] {
            return try list.map { try Reader(nodeInfo: "", jsonObject: $0, parent: parent) }
        } else {
            return []
        }
    }
}

public extension Reader {

    subscript(nodeInfo: NodeInfo) -> Reader {
        if let match = children.first(where: { nodeInfo.name == $0.nodeInfo.name }) {
            return match
        } else {
            // The queried node doesn't exist.  Return one that has nil content.
            return Reader(nodeInfo: nodeInfo, parent: self)
        }
    }

    func readIfPresent() throws -> String? {
        switch jsonNode {
        case .string(let string): return string
        default: return nil
        }
    }

    func readIfPresent() throws -> Int8? {
        switch jsonNode {
        case .number(let number): return Int8(truncating: number)
        default: return nil
        }
    }

    func readIfPresent() throws -> Int16? {
        switch jsonNode {
        case .number(let number): return Int16(truncating: number)
        default: return nil
        }
    }

    func readIfPresent() throws -> Int? {
        switch jsonNode {
        case .number(let number): return number.intValue
        default: return nil
        }
    }

    func readIfPresent() throws -> Float? {
        switch jsonNode {
        case .number(let number): return number.floatValue
        case .string(let string):
            switch string {
            case "NaN": return .nan
            case "Infinity": return .infinity
            case "-Infinity": return -.infinity
            default: return nil
            }
        default: return nil
        }
    }

    func readIfPresent() throws -> Double? {
        switch jsonNode {
        case .number(let number): return number.doubleValue
        case .string(let string):
            switch string {
            case "NaN": return .nan
            case "Infinity": return .infinity
            case "-Infinity": return -.infinity
            default: return nil
            }
        default: return nil
        }
    }

    func readIfPresent() throws -> Bool? {
        switch jsonNode {
        case .bool(let bool): return bool
        default: return nil
        }
    }

    func readIfPresent() throws -> Data? {
        switch jsonNode {
        case .string(let string): return Data(base64Encoded: Data(string.utf8))
        default: return nil
        }
    }

    func readIfPresent() throws -> Document? {
        guard let jsonObject = self.jsonObject else { return nil }
        return try Document.make(from: jsonObject)
    }

    func readTimestampIfPresent(format: SmithyTimestamps.TimestampFormat) throws -> Date? {
        switch jsonNode {
        case .string(let string): return TimestampFormatter(format: format).date(from: string)
        case .number(let number): return TimestampFormatter(format: format).date(from: "\(number)")
        default: return nil
        }
    }

    func readIfPresent<T>() throws -> T? where T: RawRepresentable, T.RawValue == Int {
        guard let rawValue: Int = try readIfPresent() else { return nil }
        return T(rawValue: rawValue)
    }

    func readIfPresent<T>() throws -> T? where T: RawRepresentable, T.RawValue == String {
        guard let rawValue: String = try readIfPresent() else { return nil }
        return T(rawValue: rawValue)
    }

    func readMapIfPresent<Value>(
        valueReadingClosure: (Reader) throws -> Value,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws -> [String: Value]? {
        if jsonNode != .object { return nil }
        var dict = [String: Value]()
        for mapEntry in children {
            let value = try valueReadingClosure(mapEntry)
            dict.updateValue(value, forKey: mapEntry.nodeInfo.name)
        }
        return dict
    }

    func readListIfPresent<Member>(
        memberReadingClosure: (Reader) throws -> Member,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws -> [Member]? {
        if jsonNode != .array { return nil }
        return try children.map { try memberReadingClosure($0) }
    }

    /// Detaches this reader from its parent.  Typically used when this reader no longer
    /// belongs in the tree, either because its data is nil or its contents were flattened
    /// into its parents.
    func detach() {
        parent?.children.removeAll { $0 === self }
        parent = nil
    }

    // MARK: - Private methods

    private var jsonObject: Any? {
        guard let jsonNode else { return nil }
        switch jsonNode {
        case .bool(let bool):
            return NSNumber(booleanLiteral: bool)
        case .number(let number):
            return number
        case .string(let string):
            return string
        case .null:
            return NSNull()
        case .array:
            return children.compactMap { $0.jsonObject }
        case .object:
            return Dictionary(uniqueKeysWithValues: children.map { ($0.nodeInfo.name, $0.jsonObject) })
        }
    }
}

public func optionalFormOf<T, Reader>(readingClosure: @escaping ReadingClosure<T, Reader>) -> ReadingClosure<T?, Reader> {
    return { reader in
        do {
            return try readingClosure(reader)
        } catch ReaderError.requiredValueNotPresent {
            return nil
        }
    }
}
