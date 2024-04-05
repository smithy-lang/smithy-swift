//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public typealias DocumentWritingClosure<T, Writer> = (T, WritingClosure<T, Writer>) throws -> Data

public func documentWritingClosure<T, Writer: SmithyWriter>(rootNodeInfo: Writer.NodeInfo) -> DocumentWritingClosure<T, Writer> {
    return { value, writingClosure in
        try DocumentWriter.write(value, rootNodeInfo: rootNodeInfo, writingClosure: writingClosure)
    }
}
