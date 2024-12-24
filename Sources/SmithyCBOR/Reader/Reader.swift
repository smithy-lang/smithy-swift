//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import Foundation

@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyReader
@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyWriter
@_spi(Smithy) import struct Smithy.Document
@_spi(Smithy) import protocol Smithy.SmithyDocument
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter
import SmithyReadWrite

@_spi(SmithyReadWrite)
public final class Reader: SmithyReader {
    public typealias NodeInfo = String

    public let cborValue: CBORType?
    public let nodeInfo: NodeInfo
    public internal(set) var children: [Reader] = []
    public internal(set) weak var parent: Reader?
    public var hasContent: Bool { cborValue != nil && cborValue != .null }

    public init(nodeInfo: NodeInfo, cborValue: CBORType?, parent: Reader? = nil) {
        self.nodeInfo = nodeInfo
        self.cborValue = cborValue
        self.parent = parent
        self.children = Self.children(from: cborValue, parent: self)
    }

    public static func from(data: Data) throws -> Reader {
        let decoder = try CBORDecoder(data: [UInt8](data))
        let rootValue: CBORType
        if decoder.hasNext() {
            rootValue = try decoder.popNext()
        } else {
            rootValue = .null
        }
        return Reader(nodeInfo: "", cborValue: rootValue, parent: nil)
    }

    private static func children(from cborValue: CBORType?, parent: Reader) -> [Reader] {
        var children = [Reader]()
        switch cborValue {
        case .map(let map):
            for (key, value) in map {
                let child = Reader(nodeInfo: key, cborValue: value, parent: parent)
                children.append(child)
            }
        case .array(let array):
            for (index, value) in array.enumerated() {
                let child = Reader(nodeInfo: "\(index)", cborValue: value, parent: parent)
                children.append(child)
            }
        default:
            break
        }
        return children
    }

    public subscript(nodeInfo: NodeInfo) -> Reader {
        if let match = children.first(where: { $0.nodeInfo == nodeInfo }) {
            return match
        } else {
            return Reader(nodeInfo: nodeInfo, cborValue: nil, parent: self)
        }
    }

    public func readIfPresent() throws -> String? {
        switch cborValue {
        case .text(let string):
            return string
        case .indef_text_start:
            // Handle concatenation of indefinite-length text
            var combinedText = ""
            for child in children {
                if let chunk = try child.readIfPresent() as String? {
                    combinedText += chunk
                }
            }
            return combinedText
        case .bytes(let data):
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }

    public func readIfPresent() throws -> Int8? {
        switch cborValue {
        case .int(let intValue): return Int8(intValue)
        case .uint(let uintValue): return Int8(uintValue)
        default: return nil
        }
    }

    public func readIfPresent() throws -> Int16? {
        switch cborValue {
        case .int(let intValue): return Int16(intValue)
        case .uint(let uintValue): return Int16(uintValue)
        default: return nil
        }
    }

    public func readIfPresent() throws -> Int? {
        switch cborValue {
        case .int(let intValue): return Int(intValue)
        case .uint(let uintValue): return Int(uintValue)
        default: return nil
        }
    }

    public func readIfPresent() throws -> Float? {
        switch cborValue {
        case .double(let doubleValue): return Float(doubleValue)
        case .int(let intValue): return Float(intValue)
        case .uint(let uintValue): return Float(uintValue)
        default: return nil
        }
    }

    public func readIfPresent() throws -> Double? {
        switch cborValue {
        case .double(let doubleValue): return doubleValue
        case .int(let intValue): return Double(intValue)
        case .uint(let uintValue): return Double(uintValue)
        default: return nil
        }
    }

    public func readIfPresent() throws -> Bool? {
        switch cborValue {
        case .bool(let boolValue): return boolValue
        default: return nil
        }
    }

    public func readIfPresent() throws -> Data? {
        switch cborValue {
        case .bytes(let data): return data
        case .text(let string): return Data(base64Encoded: string)
        default: return nil
        }
    }

    public func readIfPresent() throws -> Document? {
        guard let cborValue else { return nil }
        return Document(cborValue as! SmithyDocument)
    }

    public func readIfPresent<T>() throws -> T? where T: RawRepresentable, T.RawValue == Int {
        guard let rawValue: Int = try readIfPresent() else { return nil }
        return T(rawValue: rawValue)
    }

    public func readIfPresent<T>() throws -> T? where T: RawRepresentable, T.RawValue == String {
        guard let rawValue: String = try readIfPresent() else { return nil }
        return T(rawValue: rawValue)
    }

    public func readTimestampIfPresent(format: TimestampFormat) throws -> Date? {
        switch cborValue {
        case .double(let doubleValue):
            return Date(timeIntervalSince1970: doubleValue)
        case .int(let intValue):
            return Date(timeIntervalSince1970: Double(intValue))
        case .uint(let uintValue):
            return Date(timeIntervalSince1970: Double(uintValue))
        case .text(let string):
            return TimestampFormatter(format: format).date(from: string)
        case .date(let dateValue):
            return dateValue // Directly return the date value
        default:
            return nil
        }
    }

    public func readMapIfPresent<Value>(
        valueReadingClosure: (Reader) throws -> Value,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws -> [String: Value]? {
        guard let cborValue else { return nil }
        guard case .map(let map) = cborValue else { return nil }
        var dict = [String: Value]()
        for (key, _) in map {
            let reader = self[key]
            do {
                let value = try valueReadingClosure(reader)
                dict[key] = value
            } catch ReaderError.requiredValueNotPresent {
                if !(try reader.readNullIfPresent() ?? false) { throw ReaderError.requiredValueNotPresent }
            }
        }
        return dict
    }

    public func readListIfPresent<Member>(
        memberReadingClosure: (Reader) throws -> Member,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws -> [Member]? {
        guard let cborValue else { return nil }
        guard case .array(_) = cborValue else { return nil }

        return try children.map { child in
            // Check if the child is an indefinite-length text
            if case .indef_text_start = child.cborValue {
                var combinedText = ""
                for grandChild in child.children {
                    if let chunk = try grandChild.readIfPresent() as String? {
                        combinedText += chunk
                    }
                }
                // Return the combined text
                return combinedText as! Member
            } else {
                // Handle regular values
                return try memberReadingClosure(child)
            }
        }
    }

    public func readNullIfPresent() throws -> Bool? {
        if cborValue == .null {
            return true
        } else {
            return nil
        }
    }
}
