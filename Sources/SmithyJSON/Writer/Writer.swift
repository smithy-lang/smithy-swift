//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyReadWrite.SmithyWriter
import enum SmithyReadWrite.Document
import enum SmithyTimestamps.TimestampFormat
import struct Foundation.Data
import struct Foundation.Date

public final class Writer: SmithyWriter {
    public typealias NodeInfo = SmithyJSON.NodeInfo

    let json: JSONNode

    public required init(nodeInfo: NodeInfo) {
        self.json = .object([:])
    }

    init(json: JSONNode) {
        self.json = json
    }
}


extension Writer {

    public subscript(nodeInfo: NodeInfo) -> Writer {
        Writer(nodeInfo: "")
    }

    public func detach() {
        //
    }

    public func write<T>(_ value: T, writingClosure: (T, Writer) throws -> Void) throws {
        //
    }

    public func write(_ value: Bool?) throws {
        //
    }

    public func write(_ value: String?) throws {
        //
    }

    public func write(_ value: Double?) throws {
        //
    }

    public func write(_ value: Float?) throws {
        //
    }

    public func write(_ value: Int?) throws {
        //
    }

    public func write(_ value: Int8?) throws {
        //
    }

    public func write(_ value: Int16?) throws {
        //
    }

    public func write(_ value: UInt8?) throws {
        //
    }

    public func write(_ value: Data?) throws {
        //
    }

    public func write(_ value: Document?) throws {
        //
    }

    public func writeTimestamp(_ value: Date?, format: SmithyTimestamps.TimestampFormat) throws {
        //
    }

    public func write<T>(_ value: T?) throws where T : RawRepresentable, T.RawValue == Int {
        //
    }

    public func write<T>(_ value: T?) throws where T : RawRepresentable, T.RawValue == String {
        //
    }

    public func writeMap<T>(_ value: [String : T]?, valueWritingClosure: (T, Writer) throws -> Void, keyNodeInfo: NodeInfo, valueNodeInfo: NodeInfo, isFlattened: Bool) throws {
        //
    }

    public func writeList<T>(_ value: [T]?, memberWritingClosure: (T, Writer) throws -> Void, memberNodeInfo: NodeInfo, isFlattened: Bool) throws {
        //
    }
}
