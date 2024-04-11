//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public enum DocumentReader {

    public static func read<T, Reader: SmithyReader>(
        _ data: Data,
        readingClosure: ReadingClosure<T, Reader>
    ) throws -> T {
        let reader = try Reader.from(data: data)
        return try readingClosure(reader)
    }
}
