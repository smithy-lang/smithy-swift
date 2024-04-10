//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public enum DocumentWriter {

    public static func write<T, Writer: SmithyWriter>(
        _ value: T,
        rootNodeInfo: Writer.NodeInfo,
        writingClosure: WritingClosure<T, Writer>
    ) throws -> Data? {
        let writer = Writer(nodeInfo: rootNodeInfo)
        try writingClosure(value, writer)
        return try writer.data()
    }
}
