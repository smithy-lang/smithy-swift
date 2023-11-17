//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import typealias SmithyReadWrite.WritingClosure

public class DocumentWriter {

    init() {}

    func write<T>(_ value: T, rootNodeInfo: NodeInfo, writingClosure: WritingClosure<T, Writer>) throws -> Data {
        let writer = Writer(rootNodeInfo: rootNodeInfo)
        try writingClosure(value, writer)
        return Data(writer.element.xmlString.utf8)
    }
}
