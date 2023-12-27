//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import typealias SmithyReadWrite.DocumentWritingClosure

public enum XMLReadWrite {

    public static func documentWritingClosure<T>(rootNodeInfo: NodeInfo) -> DocumentWritingClosure<T, Writer> {
        return { value, writingClosure in
            try DocumentWriter.write(value, rootNodeInfo: rootNodeInfo, writingClosure: writingClosure)
        }
    }
}
