//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyReadWrite.SmithyReader
import enum SmithyReadWrite.Document
import enum SmithyTimestamps.TimestampFormat
import struct Foundation.Data
import struct Foundation.Date

public final class Reader: SmithyReader {
    public typealias NodeInfo = SmithyJSON.NodeInfo

    public let nodeInfo: NodeInfo
    public let children = [Reader]()
    public var content: String? = nil

    init(nodeInfo: NodeInfo) {
        self.nodeInfo = nodeInfo
    }
}

public extension Reader {

    subscript(nodeInfo: NodeInfo) -> Reader {
        Reader(nodeInfo: "")
    }

    func readIfPresent<T>(readingClosure: (Reader) throws -> T?) throws -> T? {
        nil
    }

    func readIfPresent() throws -> String? {
        nil
    }

    func readIfPresent() throws -> Int8? {
        nil
    }

    func readIfPresent() throws -> Int16? {
        nil
    }

    func readIfPresent() throws -> Int? {
        nil
    }

    func readIfPresent() throws -> Float? {
        nil
    }

    func readIfPresent() throws -> Double? {
        nil
    }

    func readIfPresent() throws -> Bool? {
        nil
    }

    func readIfPresent() throws -> Data? {
        nil
    }

    func readIfPresent() throws -> Document? {
        nil
    }

    func readTimestampIfPresent(format: SmithyTimestamps.TimestampFormat) throws -> Date? {
        nil
    }

    func readIfPresent<T>() throws -> T? where T : RawRepresentable, T.RawValue == Int {
        nil
    }

    func readIfPresent<T>() throws -> T? where T : RawRepresentable, T.RawValue == String {
        nil
    }

    func readMapIfPresent<T>(valueReadingClosure: (Reader) throws -> T??, keyNodeInfo: NodeInfo, valueNodeInfo: NodeInfo, isFlattened: Bool) throws -> [String : T]? {
        nil
    }

    func readListIfPresent<Member>(memberReadingClosure: (Reader) throws -> Member?, memberNodeInfo: NodeInfo, isFlattened: Bool) throws -> [Member]? {
        nil
    }

    func detach() {
        //
    }
}
