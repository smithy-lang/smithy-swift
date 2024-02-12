//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import typealias SmithyReadWrite.DocumentWritingClosure
import typealias SmithyReadWrite.DocumentReadingClosure

public enum XMLReadWrite {

    public static func documentWritingClosure<T>(rootNodeInfo: NodeInfo) -> DocumentWritingClosure<T, Writer> {
        return { value, writingClosure in
            try DocumentWriter.write(value, rootNodeInfo: rootNodeInfo, writingClosure: writingClosure)
        }
    }

    public static func documentReadingClosure<T>(rootNodeInfo: NodeInfo) -> DocumentReadingClosure<T, Reader> {
        return { data, readingClosure in
            try DocumentReader.read(data, readingClosure: readingClosure)
        }
    }
}
