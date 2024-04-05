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
    public typealias NodeInfo = SmithyFormURL.NodeInfo

    let formURL: FormURLNode

    public required init(nodeInfo: NodeInfo) {
        //
        formURL = .init()
    }

    init(formURL: FormURLNode) {
        self.formURL = formURL
    }
}

public extension Writer {

    func data() throws -> Data {
        Data()
    }

    func detach() {}

    subscript(nodeInfo: NodeInfo) -> Writer {
        Writer(nodeInfo: "")
    }

    func write<T>(_ value: T, writingClosure: (T, Writer) throws -> Void) throws {
        //
    }

    func write(_ value: Bool?) throws {
        //
    }

    func write(_ value: String?) throws {
        //
    }

    func write(_ value: Double?) throws {
        //
    }

    func write(_ value: Float?) throws {
        //
    }

    func write(_ value: Int?) throws {
        //
    }

    func write(_ value: Int8?) throws {
        //
    }

    func write(_ value: Int16?) throws {
        //
    }

    func write(_ value: UInt8?) throws {
        //
    }

    func write(_ value: Data?) throws {
        //
    }

    func write(_ value: Document?) throws {
        // No operation.  Smithy document not supported in FormURL
    }

    func writeTimestamp(_ value: Date?, format: SmithyTimestamps.TimestampFormat) throws {
        //
    }

    func write<T>(_ value: T?) throws where T : RawRepresentable, T.RawValue == Int {
        //
    }

    func write<T>(_ value: T?) throws where T : RawRepresentable, T.RawValue == String {
        //
    }

    func writeMap<T>(_ value: [String : T]?, valueWritingClosure: (T, Writer) throws -> Void, keyNodeInfo: NodeInfo, valueNodeInfo: NodeInfo, isFlattened: Bool) throws {
        //
    }

    func writeList<T>(_ value: [T]?, memberWritingClosure: (T, Writer) throws -> Void, memberNodeInfo: NodeInfo, isFlattened: Bool) throws {
        //
    }

}

public struct FormURLNode {}
