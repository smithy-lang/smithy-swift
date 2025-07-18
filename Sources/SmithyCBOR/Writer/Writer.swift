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
@_spi(SmithyReadWrite) import enum SmithyReadWrite.WriterError
@_spi(Smithy) import struct Smithy.Document
@_spi(Smithy) import protocol Smithy.SmithyDocument
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

@_spi(SmithyReadWrite)
public final class Writer: SmithyWriter {
    let nodeInfo: NodeInfo
    var cborValue: CBORType?
    var children: [Writer] = []
    weak var parent: Writer?

    public required init(nodeInfo: NodeInfo) {
        self.nodeInfo = nodeInfo
    }

    public required init(nodeInfo: NodeInfo, parent: Writer? = nil) {
        self.nodeInfo = nodeInfo
        self.parent = parent
    }

    public func data() throws -> Data {
        let encoder = try CBOREncoder()
        try encode(encoder: encoder)
        let encodedBytes = encoder.getEncoded()
        return Data(encodedBytes)
    }

    private func encode(encoder: CBOREncoder) throws {
        if let cborValue = self.cborValue {
            // Encode the CBOR value directly if it exists
            encoder.encode(cborValue)
        } else if !children.isEmpty {
            // Encode as an indefinite-length map
            encoder.encode(.indef_map_start)
            for child in children {
                guard !(child.cborValue == nil && child.children.isEmpty) else {
                    continue
                }
                encoder.encode(.text(child.nodeInfo.name)) // Key for the child

                if let cborValue = child.cborValue {
                    encoder.encode(cborValue) // Encode the value directly
                } else {
                    try child.encode(encoder: encoder) // Recursively encode nested maps/arrays
                }
            }
            encoder.encode(.indef_break)
        } else {
            // No value and no children: encode an empty map
            encoder.encode(.indef_map_start)
            encoder.encode(.indef_break)
        }
    }

    public subscript(nodeInfo: NodeInfo) -> Writer {
        if let child = children.first(where: { $0.nodeInfo == nodeInfo }) {
            return child
        } else {
            let newChild = Writer(nodeInfo: nodeInfo, parent: self)
            children.append(newChild)
            return newChild
        }
    }

    public func write(_ value: Bool?) throws {
        guard let value else { return }
        self.cborValue = .bool(value)
    }

    public func write(_ value: String?) throws {
        guard let value else { return }
        self.cborValue = .text(value)
    }

    public func write(_ value: Float?) throws {
        guard let value else { return }
        self.cborValue = .double(Double(value))
    }

    public func write(_ value: Double?) throws {
        guard let value else { return }
        self.cborValue = .double(value)
    }

    public func write(_ value: Int?) throws {
        guard let value else { return }
        self.cborValue = .int(Int64(value))
    }

    public func write(_ value: Int8?) throws {
        guard let value else { return }
        self.cborValue = .int(Int64(value))
    }

    public func write(_ value: Int16?) throws {
        guard let value else { return }
        self.cborValue = .int(Int64(value))
    }

    public func write(_ value: UInt8?) throws {
        guard let value else { return }
        self.cborValue = .uint(UInt64(value))
    }

    public func write(_ value: Data?) throws {
        guard let value else { return }
        self.cborValue = .bytes(value)
    }

    public func write(_ value: SmithyDocument?) throws {
        // No operation.  Smithy document not supported in CBOR
    }

    public func writeTimestamp(_ value: Date?, format: TimestampFormat) throws {
        guard let value else { return }
        switch format {
        case .epochSeconds:
            self.cborValue = .date(value)
        default:
            throw WriterError.invalidType("Only .epochSeconds timestamp format is supported!")
        }
    }

    public func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == Int {
        if let rawValue = value?.rawValue {
            try write(rawValue)
        }
    }

    public func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == String {
        if let rawValue = value?.rawValue {
            try write(rawValue)
        }
    }

    public func writeMap<T>(
        _ value: [String: T]?,
        valueWritingClosure: (T, Writer) throws -> Void,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { return }
        var map: [String: CBORType] = [:]
        for (key, val) in value {
            let writer = self[.init(key)]
            try valueWritingClosure(val, writer)

            if let cborValue = extractCBORValue(from: writer) {
                map[key] = cborValue
            }
        }
        self.cborValue = .map(map)
    }

    public func writeList<T>(
        _ value: [T]?,
        memberWritingClosure: (T, Writer) throws -> Void,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { return }
        var array: [CBORType] = []
        for val in value {
            // Create a child writer for each list element
            let childWriter = Writer(nodeInfo: memberNodeInfo, parent: self)
            try memberWritingClosure(val, childWriter)
            if let cborValue = extractCBORValue(from: childWriter) {
                array.append(cborValue)
            }
        }
        self.cborValue = .array(array)
    }

    public func writeNull() throws {
        self.cborValue = .null
    }

    private func extractCBORValue(from writer: Writer) -> CBORType? {
        // If the writer has a value, return it immediately
        if let value = writer.cborValue {
            return value
        }
        // Otherwise, if it has children, recursively check each child
        if !writer.children.isEmpty {
            var childMap: [String: CBORType] = [:]
            for child in writer.children {
                if let childValue = extractCBORValue(from: child) {
                    childMap[child.nodeInfo.name] = childValue
                }
            }
            // Return a map if any children provided a value
            if !childMap.isEmpty {
                return .map(childMap)
            }
        }
        // No value found at any level
        return nil
    }
}
